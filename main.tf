provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--profile", var.aws_profile, "--region", var.region]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--profile", var.aws_profile, "--region", var.region]
    }
  }
}

data "aws_caller_identity" "current" {}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = var.vpc_cidr

  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  azs                 = var.azs
  private_subnets     = var.private_subnets
  public_subnets      = var.public_subnets
  database_subnets    = var.database_subnets
  elasticache_subnets = var.elasticache_subnets
  intra_subnets       = var.intra_subnets

  create_database_subnet_group       = var.create_database_subnet_group
  create_elasticache_subnet_group    = var.create_elasticache_subnet_group
  create_database_subnet_route_table = var.create_database_subnet_route_table
  one_nat_gateway_per_az             = var.one_nat_gateway_per_az


  enable_nat_gateway = var.enable_nat_gateway
  enable_vpn_gateway = var.enable_vpn_gateway

  tags = var.default_tags
}

locals {
  eks_aws_auth_roles = distinct(flatten(
    [
      for role in var.eks_aws_auth_roles : [
        {
          rolearn  = role
          username = element(split("/", role), 1)
          groups = [
            "system:masters"
          ]
        }
      ]
    ]
    )
  )

  eks_aws_auth_users = distinct(flatten(
    [
      for user in var.eks_aws_auth_users : [
        {
          userarn  = user
          username = element(split("/", user), 1)
          groups   = ["system:masters"]
        }
      ]
    ]
    )
  )
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access = var.eks_cluster_endpoint_public_access

  cluster_addons = var.eks_cluster_addons

  enable_irsa = var.eks_enable_irsa

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = var.eks_managed_node_group_defaults_instance_types
  }

  eks_managed_node_groups = {
    seqera = {
      min_size     = var.eks_managed_node_group_min_size
      max_size     = var.eks_managed_node_group_max_size
      desired_size = var.eks_managed_node_group_desired_size

      instance_types = var.eks_managed_node_group_defaults_instance_types
      capacity_type  = var.eks_managed_node_group_defaults_capacity_type
    }
  }

  manage_aws_auth_configmap = var.eks_manage_aws_auth_configmap
  aws_auth_roles            = local.eks_aws_auth_roles
  aws_auth_users            = local.eks_aws_auth_users

  tags = var.default_tags
}

resource "kubernetes_namespace_v1" "this" {
  count = var.create_seqera_namespace ? 1 : 0 || var.create_seqera_service_account ? 1 : 0

  metadata {
    name = var.seqera_namespace_name
  }
}

resource "kubernetes_service_account_v1" "this" {
  count = var.create_seqera_service_account ? 1 : 0

  metadata {
    name      = var.seqera_service_account_name
    namespace = var.seqera_namespace_name
  }

  automount_service_account_token = true

  depends_on = [kubernetes_namespace_v1.this]
}

resource "null_resource" "ingress_crd" {
  count = var.enable_aws_loadbalancer_controller ? 1 : 0

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --profile ${var.environment} && kubectl apply -k 'github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master'"
  }

  depends_on = [
    module.eks
  ]
}

resource "helm_release" "aws-load-balancer-controller" {
  count = var.enable_aws_loadbalancer_controller ? 1 : 0

  name            = "aws-load-balancer-controller"
  repository      = "https://aws.github.io/eks-charts"
  chart           = "aws-load-balancer-controller"
  namespace       = "kube-system"
  atomic          = true
  cleanup_on_fail = true
  replace         = true

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = false
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = module.vpc.vpc_id
  }

  depends_on = [
    null_resource.ingress_crd,
    module.eks
  ]
}

module "db_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = var.db_security_group_name
  description = "Security group for access from seqera EKS cluster to seqera db"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = module.vpc.private_subnets_cidr_blocks
}

module "redis_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = var.redis_security_group_name
  description = "Security group for access from seqera EKS cluster to seqera redis"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = module.vpc.private_subnets_cidr_blocks
}

module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = var.database_identifier

  engine              = "mysql"
  engine_version      = var.db_engine_version
  instance_class      = var.db_instance_class
  allocated_storage   = var.db_allocated_storage
  skip_final_snapshot = var.db_skip_final_snapshot

  db_name  = var.db_name
  username = var.db_username
  port     = var.db_port
  password = var.db_password

  iam_database_authentication_enabled = var.db_iam_database_authentication_enabled

  vpc_security_group_ids = [module.db_sg.security_group_id]

  maintenance_window = var.db_maintenance_window
  backup_window      = var.db_backup_window

  # Enhanced Monitoring - see example for details on how to create the role
  # by yourself, in case you don't want to create it automatically
  monitoring_interval    = var.db_monitoring_interval
  monitoring_role_name   = var.db_monitoring_role_name
  create_monitoring_role = var.db_create_monitoring_role

  tags = var.default_tags

  # DB subnet group
  db_subnet_group_name = module.vpc.database_subnet_group_name

  # DB parameter group
  family = var.db_family

  # DB option group
  major_engine_version = var.db_major_engine_version

  # Database Deletion Protection
  deletion_protection = var.db_deletion_protection

  parameters = var.db_parameters
  options    = var.db_options
}

module "memory_db" {
  source = "terraform-aws-modules/memory-db/aws"

  # Cluster
  name        = var.redis_cluster_name
  description = "seqera MemoryDB cluster"

  engine_version             = var.redis_engine_version
  auto_minor_version_upgrade = var.redis_auto_minor_version_upgrade
  node_type                  = var.redis_node_type
  num_shards                 = var.redis_num_shards
  num_replicas_per_shard     = var.redis_num_replicas_per_shard

  tls_enabled              = var.redis_tls_enabled
  security_group_ids       = [module.redis_sg.security_group_id]
  maintenance_window       = var.redis_maintenance_window
  snapshot_retention_limit = var.redis_snapshot_retention_limit
  snapshot_window          = var.redis_snapshot_window

  # Users
  users = var.redis_users

  # Parameter group
  parameter_group_name        = var.redis_parameter_group_name
  parameter_group_description = var.redis_parameter_group_description
  parameter_group_family      = var.redis_parameter_group_family
  parameter_group_parameters  = var.redis_parameter_group_parameters
  parameter_group_tags        = var.redis_parameter_group_tags

  # Subnet group
  create_subnet_group      = var.redis_create_subnet_group
  subnet_group_name        = var.redis_subnet_group_name
  subnet_group_description = var.redis_subnet_group_description
  subnet_ids               = module.vpc.elasticache_subnets

  tags = var.default_tags
}

locals {
  seqera_irsa_role_name       = "${var.seqera_irsa_role_name}-${var.cluster_name}-${var.region}"
  seqera_irsa_iam_policy_name = "${var.seqera_irsa_iam_policy_name}-${var.cluster_name}-${var.region}"
}

module "seqera_iam_policy" {
  source = "terraform-aws-modules/iam/aws//modules/iam-policy"

  name        = local.seqera_irsa_iam_policy_name
  path        = "/"
  description = "This policy provide the permissions needed for seqera service account to be able to interact with the required AWS services."

  policy = var.seqera_platform_service_account_iam_policy
}

module "seqera_irsa" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = local.seqera_irsa_role_name

  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${var.seqera_namespace_name}:${var.seqera_service_account_name}"]
    }
  }

  role_policy_arns = {
    AmazonEKS_CNI_Policy = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    additional           = module.seqera_iam_policy.arn
  }

  tags = {
    Name = local.seqera_irsa_role_name
  }
}

