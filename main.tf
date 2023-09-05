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

provider "kubectl" {
  apply_retry_count      = 5
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--profile", var.aws_profile, "--region", var.region]
  }
}

provider "helm" {
  debug = true
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

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "kubernetes.io/cluster/CLUSTER_NAME"        = var.cluster_name
    "kubernetes.io/role/internal-elb"           = "1"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "kubernetes.io/cluster/CLUSTER_NAME"        = var.cluster_name
    "kubernetes.io/role/elb"                    = "1"
  }

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
    instance_types               = var.eks_managed_node_group_defaults_instance_types
    iam_role_additional_policies = local.additional_policies
    subnet_ids                   = module.vpc.private_subnets
  }

  eks_managed_node_groups = {
    seqera = {
      min_size     = var.eks_managed_node_group_min_size
      max_size     = var.eks_managed_node_group_max_size
      desired_size = var.eks_managed_node_group_desired_size

      instance_types = var.eks_managed_node_group_defaults_instance_types
      capacity_type  = var.eks_managed_node_group_defaults_capacity_type
      subnet_ids     = module.vpc.private_subnets
    }
  }

  iam_role_additional_policies = local.additional_policies

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
    annotations = {
      "eks.amazonaws.com/role-arn" = module.seqera_irsa.iam_role_arn
    }
  }

  automount_service_account_token = true

  depends_on = [kubernetes_namespace_v1.this]
}

resource "helm_release" "aws_cluster_autoscaler" {
  count = var.enable_aws_cluster_autoscaler ? 1 : 0

  name       = "aws-cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  version    = var.aws_cluster_autoscaler_version
  replace    = true
  atomic     = true
  wait       = true

  set {
    name = "autoDiscovery.clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "awsRegion"
    value = var.region
  }

  depends_on = [
    module.eks
  ]
}

resource "null_resource" "ingress_crd" {
  count = var.enable_aws_loadbalancer_controller ? 1 : 0

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --profile ${var.aws_profile} && kubectl apply -k 'github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master'"
  }

  depends_on = [
    module.eks
  ]
}

resource "helm_release" "aws-ebs-csi-driver" {
  count = var.enable_ebs_csi_driver ? 1 : 0

  name       = "aws-ebs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver/"
  chart      = "aws-ebs-csi-driver"
  namespace  = "kube-system"
  version    = var.ebs_csi_driver_version
  replace    = true
  atomic     = true
  wait       = true

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
  version         = var.aws_loadbalancer_controller_version
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
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = module.vpc.vpc_id
  }

  depends_on = [
    module.eks
  ]
}

module "db_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = var.db_security_group_name
  description = "Security group for access from seqera EKS cluster to seqera db"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = module.vpc.private_subnets_cidr_blocks
  ingress_rules       = [var.db_ingress_rule]
}

module "redis_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = var.redis_security_group_name
  description = "Security group for access from seqera EKS cluster to seqera redis"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = module.vpc.private_subnets_cidr_blocks
  ingress_rules       = [var.redis_ingress_rule]
}

module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier                  = var.database_identifier
  manage_master_user_password = var.db_manage_master_user_password

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
  create_acl               = var.redis_create_acl
  acl_name                 = var.redis_create_acl ? var.redis_acl_name : "open-access"

  # Users
  users = var.redis_create_acl ? var.redis_users : {}

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
  seqera_irsa_role_name                       = "${var.seqera_irsa_role_name}-${var.cluster_name}-${var.region}"
  seqera_irsa_iam_policy_name                 = "${var.seqera_irsa_iam_policy_name}-${var.cluster_name}-${var.region}"
  aws_loadbalancer_controller_iam_policy_name = "${var.aws_loadbalancer_controller_iam_policy_name}-${var.cluster_name}-${var.region}"
  aws_cluster_autoscaler_iam_policy_name      = "${var.aws_cluster_autoscaler_iam_policy_name}-${var.cluster_name}-${var.region}"
  ebs_csi_driver_iam_policy_name              = "${var.ebs_csi_driver_iam_policy_name}-${var.cluster_name}-${var.region}"

# This code now has 7 conditions, where each one is an individual combination of the three boolean variables 
# (var.enable_aws_loadbalancer_controller, var.enable_ebs_csi_driver, and var.enable_aws_cluster_autoscaler). 
# The last condition simply defaults to an empty map if none of the three are enabled.

additional_policies = var.enable_aws_loadbalancer_controller && var.enable_ebs_csi_driver && var.enable_aws_cluster_autoscaler ? {
    aws_loadbalancer_controller_iam_policy = module.aws_loadbalancer_controller_iam_policy[0].arn
    ebs_csi_driver_iam_policy              = module.ebs_csi_driver_iam_policy[0].arn
    aws_cluster_autoscaler_iam_policy      = module.aws_cluster_autoscaler_iam_policy[0].arn
  } : var.enable_aws_loadbalancer_controller && var.enable_ebs_csi_driver && !var.enable_aws_cluster_autoscaler ? {
    aws_loadbalancer_controller_iam_policy = module.aws_loadbalancer_controller_iam_policy[0].arn
    ebs_csi_driver_iam_policy              = module.ebs_csi_driver_iam_policy[0].arn
  } : var.enable_aws_loadbalancer_controller && !var.enable_ebs_csi_driver && var.enable_aws_cluster_autoscaler ? {
    aws_loadbalancer_controller_iam_policy = module.aws_loadbalancer_controller_iam_policy[0].arn
    aws_cluster_autoscaler_iam_policy      = module.aws_cluster_autoscaler_iam_policy[0].arn
  } : !var.enable_aws_loadbalancer_controller && var.enable_ebs_csi_driver && var.enable_aws_cluster_autoscaler ? {
    ebs_csi_driver_iam_policy              = module.ebs_csi_driver_iam_policy[0].arn
    aws_cluster_autoscaler_iam_policy      = module.aws_cluster_autoscaler_iam_policy[0].arn
  } : var.enable_aws_loadbalancer_controller && !var.enable_ebs_csi_driver && !var.enable_aws_cluster_autoscaler ? {
    aws_loadbalancer_controller_iam_policy = module.aws_loadbalancer_controller_iam_policy[0].arn
  } : !var.enable_aws_loadbalancer_controller && var.enable_ebs_csi_driver && !var.enable_aws_cluster_autoscaler ? {
    ebs_csi_driver_iam_policy = module.ebs_csi_driver_iam_policy[0].arn
  } :!var.enable_aws_loadbalancer_controller && !var.enable_ebs_csi_driver && var.enable_aws_cluster_autoscaler ? {
    aws_cluster_autoscaler_iam_policy = module.aws_cluster_autoscaler_iam_policy[0].arn
  } : {}  # This last case covers the scenario where none of the three are enabled
}

module "seqera_iam_policy" {
  source = "terraform-aws-modules/iam/aws//modules/iam-policy"

  name        = local.seqera_irsa_iam_policy_name
  path        = "/"
  description = "This policy provide the permissions needed for seqera service account to be able to interact with the required AWS services."

  policy = var.seqera_platform_service_account_iam_policy

  tags = var.default_tags
}

module "aws_loadbalancer_controller_iam_policy" {
  source = "terraform-aws-modules/iam/aws//modules/iam-policy"
  count  = var.enable_aws_loadbalancer_controller ? 1 : 0

  name        = local.aws_loadbalancer_controller_iam_policy_name
  path        = "/"
  description = "This policy provide the permissions needed for AWS loadBalancer controller"

  policy = var.aws_loadbalancer_controller_iam_policy

  tags = var.default_tags
}

module "aws_cluster_autoscaler_iam_policy" {
  source = "terraform-aws-modules/iam/aws//modules/iam-policy"
  count  = var.enable_aws_cluster_autoscaler ? 1 : 0

  name        = local.aws_cluster_autoscaler_iam_policy_name
  path        = "/"
  description = "This policy provide the permissions needed for AWS cluster autoscaler"

  policy = var.aws_cluster_autoscaler_iam_policy

  tags = var.default_tags
}

module "ebs_csi_driver_iam_policy" {
  source = "terraform-aws-modules/iam/aws//modules/iam-policy"
  count  = var.enable_ebs_csi_driver ? 1 : 0

  name        = local.ebs_csi_driver_iam_policy_name
  path        = "/"
  description = "This policy provide the permissions needed for EBS CSI driver"

  policy = var.ebs_csi_driver_iam_policy

  tags = var.default_tags
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

