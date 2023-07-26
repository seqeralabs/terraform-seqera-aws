provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--profile", var.aws_profile]
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
            username = "system:node:{{SessionName}}"
            groups = [
              "system:bootstrappers",
              "system:nodes",
              "system:node-proxier",
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
            username = "user1"
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
    tower = {
      min_size     = var.eks_managed_node_group_min_size
      max_size     = var.eks_managed_node_group_max_size
      desired_size = var.eks_managed_node_group_desired_size

      instance_types = var.eks_managed_node_group_defaults_instance_types
      capacity_type  = var.eks_managed_node_group_defaults_capacity_type
    }
  }

  manage_aws_auth_configmap = var.eks_manage_aws_auth_configmap
  aws_auth_roles = local.eks_aws_auth_roles
  aws_auth_users = local.eks_aws_auth_users

  tags = var.default_tags
}

module "db_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = var.db_security_group_name
  description = "Security group for access from Tower EKS cluster to tower db"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = module.vpc.private_subnets_cidr_blocks
}

module "redis_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = var.redis_security_group_name
  description = "Security group for access from Tower EKS cluster to tower redis"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = module.vpc.private_subnets_cidr_blocks
}

module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = var.database_identifier

  engine            = "mysql"
  engine_version    = var.db_engine_version
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage

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
  description = "Tower MemoryDB cluster"

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

module "iam_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"

  name        = var.tower_irsa_iam_policy_name
  path        = "/"
  description = "This policy provide the permissions needed for Tower service account to be able to interact with the required AWS services."

  policy = var.tower_service_account_iam_policy
}

module "tower_irsa" {
  source      = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name   = var.tower_irsa_role_name

  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${var.tower_namespace_name}:${var.tower_namespace_name}"]
    }
  }

  role_policy_arns = {
    AmazonEKS_CNI_Policy = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    additional           = module.iam_policy.arn
  }

  tags = {
    Name = var.tower_irsa_role_name
  }
}