## Environment
variable "environment" {
  type        = string
  default     = ""
  description = "The environment in which the infrastructure is being deployed."
}

## Region
variable "region" {
  type        = string
  default     = "eu-west-2"
  description = "The AWS region in which the resources will be provisioned."
}

## Tags
variable "default_tags" {
  type = map(string)
  default = {
    ManagedBy   = "Terraform"
    Product     = "Tower"
  }
  description = "Default tags to be applied to the provisioned resources."
}

## AWS Profile
variable "aws_profile" {
  type        = string
  default = "default"
  description = "The AWS profile used for authentication when interacting with AWS resources."
}

## VPC Name
variable "vpc_name" {
  type        = string
  description = "The name of the Virtual Private Cloud (VPC) to be created."
}

## VPC CIDR
variable "vpc_cidr" {
  type        = string
  description = "The CIDR block for the VPC."
}

## Cluster Endpoint Public Access
variable "eks_cluster_endpoint_public_access" {
  type        = bool
  default     = true
  description = "Determines whether the EKS cluster endpoint is publicly accessible."
}

## EKS Cluster Addons
variable "eks_cluster_addons" {
  type = map(object({
    most_recent = bool
  }))
  default = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }
  description = "Addons to be enabled for the EKS cluster."
}

## EKS Managed Node Group - Minimum Size
variable "eks_managed_node_group_min_size" {
  type        = number
  default     = 1
  description = "The minimum size of the EKS managed node group."
}

variable "eks_manage_aws_auth_configmap" {
  type = bool 
  default = true
  description = "Determines whether to manage the aws-auth ConfigMap."
}

variable "eks_aws_auth_roles" {
  type = list(string)
  default = []
  description = "List of roles ARNs to add to the aws-auth config map"
}

variable "eks_aws_auth_users" {
  type = list(string)
  default = []
  description = "List of users ARNs to add to the aws-auth config map"
}

## Tower Service Account IRSA IAM Policy
variable "tower_service_account_iam_policy" {
  type = string 
  description = "IAM policy for the Tower service account"
  default = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Sid": "TowerForge0",
          "Effect": "Allow",
          "Action": [
              "ssm:GetParameters",
              "iam:CreateInstanceProfile",
              "iam:DeleteInstanceProfile",
              "iam:GetRole",
              "iam:RemoveRoleFromInstanceProfile",
              "iam:CreateRole",
              "iam:DeleteRole",
              "iam:AttachRolePolicy",
              "iam:PutRolePolicy",
              "iam:AddRoleToInstanceProfile",
              "iam:PassRole",
              "iam:DetachRolePolicy",
              "iam:ListAttachedRolePolicies",
              "iam:DeleteRolePolicy",
              "iam:ListRolePolicies",
              "iam:TagRole",
              "iam:TagInstanceProfile",
              "batch:CreateComputeEnvironment",
              "batch:DescribeComputeEnvironments",
              "batch:CreateJobQueue",
              "batch:DescribeJobQueues",
              "batch:UpdateComputeEnvironment",
              "batch:DeleteComputeEnvironment",
              "batch:UpdateJobQueue",
              "batch:DeleteJobQueue",
              "batch:TagResource",
              "fsx:DeleteFileSystem",
              "fsx:DescribeFileSystems",
              "fsx:CreateFileSystem",
              "fsx:TagResource",
              "ec2:DescribeSecurityGroups",
              "ec2:DescribeAccountAttributes",
              "ec2:DescribeSubnets",
              "ec2:DescribeLaunchTemplates",
              "ec2:DescribeLaunchTemplateVersions", 
              "ec2:CreateLaunchTemplate",
              "ec2:DeleteLaunchTemplate",
              "ec2:DescribeKeyPairs",
              "ec2:DescribeVpcs",
              "ec2:DescribeInstanceTypeOfferings",
              "ec2:GetEbsEncryptionByDefault",
              "elasticfilesystem:DescribeMountTargets",
              "elasticfilesystem:CreateMountTarget",
              "elasticfilesystem:CreateFileSystem",
              "elasticfilesystem:DescribeFileSystems",
              "elasticfilesystem:DeleteMountTarget",
              "elasticfilesystem:DeleteFileSystem",
              "elasticfilesystem:UpdateFileSystem",
              "elasticfilesystem:PutLifecycleConfiguration",
              "elasticfilesystem:TagResource"
          ],
          "Resource": "*"
      },
      {
          "Sid": "TowerLaunch0",
          "Effect": "Allow",
          "Action": [
              "s3:Get*",
              "s3:List*",
              "batch:DescribeJobQueues",
              "batch:CancelJob",
              "batch:SubmitJob",
              "batch:ListJobs",
              "batch:DescribeComputeEnvironments",
              "batch:TerminateJob",
              "batch:DescribeJobs",
              "batch:RegisterJobDefinition",
              "batch:DescribeJobDefinitions",
              "ecs:DescribeTasks",
              "ec2:DescribeInstances",
              "ec2:DescribeInstanceTypes",
              "ec2:DescribeInstanceAttribute",
              "ecs:DescribeContainerInstances",
              "ec2:DescribeInstanceStatus",
              "ec2:DescribeImages",
              "logs:Describe*",
              "logs:Get*",
              "logs:List*",
              "logs:StartQuery",
              "logs:StopQuery",
              "logs:TestMetricFilter",
              "logs:FilterLogEvents"
          ],
          "Resource": "*"
      }
  ]
}
EOF 
}

## Tower Namespace Name
variable "tower_namespace_name" {
  type = string 
  default = "tower"
  description = "The name of the namespace used to deploy Tower manifests."
}

## Tower Service Account Name
variable "tower_service_account_name" {
  type = string 
  description = "Name for the Tower service account"
  default = "tower-sa"
}

## EKS Enable IRSA
variable "eks_enable_irsa" {
  type = bool 
  default = true 
  description = "Determines whether to create an OpenID Connect Provider for EKS to enable IRSA"
}

## EKS Managed Node Group - Maximum Size
variable "eks_managed_node_group_max_size" {
  type        = number
  default     = 5
  description = "The maximum size of the EKS managed node group."
}

## EKS Managed Node Group - Desired Size
variable "eks_managed_node_group_desired_size" {
  type        = number
  default     = 1
  description = "The desired size of the EKS managed node group."
}

## VPC Subnets
variable "intra_subnets" {
  type        = list(string)
  description = "A list of subnet IDs for intra subnets within the VPC."
}

variable "public_subnets" {
  type        = list(string)
  description = "A list of subnet IDs for public subnets within the VPC."
}

variable "private_subnets" {
  type        = list(string)
  description = "A list of subnet IDs for private subnets within the VPC."
}

variable "database_subnets" {
  type        = list(string)
  description = "A list of subnet IDs for database subnets within the VPC."
}

variable "elasticache_subnets" {
  type        = list(string)
  description = "A list of subnet IDs for Elasticache subnets within the VPC."
}

variable "enable_dns_hostnames" {
  type        = bool
  default     = true
  description = "Determines whether instances in the VPC receive DNS hostnames."
}

variable "enable_dns_support" {
  type        = bool
  default     = true
  description = "Determines whether DNS resolution is supported for the VPC."
}

variable "create_database_subnet_group" {
  type        = bool
  default     = true
  description = "Determines whether a database subnet group should be created."
}

variable "create_elasticache_subnet_group" {
  type        = bool
  default     = false
  description = "Determines whether an Elasticache subnet group should be created."
}

variable "create_database_subnet_route_table" {
  type        = bool
  default     = true
  description = "Determines whether a subnet route table should be created for the database subnets."
}

variable "one_nat_gateway_per_az" {
  type        = bool
  default     = true
  description = "Determines whether each Availability Zone should have a dedicated NAT gateway."
}

variable "enable_nat_gateway" {
  type        = bool
  default     = true
  description = "Determines whether NAT gateways should be provisioned."
}

variable "enable_vpn_gateway" {
  type        = bool
  default     = true
  description = "Determines whether a VPN gateway should be provisioned."
}

## Availability Zones
variable "azs" {
  type        = list(string)
  description = "A list of Availability Zones in the selected region."
}

## EKS
variable "cluster_name" {
  type        = string
  description = "The name of the EKS cluster."
}

variable "cluster_version" {
  type        = string
  default     = "1.27"
  description = "The version of Kubernetes to use for the EKS cluster."
}

variable "eks_managed_node_group_defaults_instance_types" {
  type        = list(string)
  default     = ["m5a.2xlarge"]
  description = "A list of EC2 instance types for the default managed node group."
}

variable "eks_managed_node_group_defaults_capacity_type" {
  type        = string
  default     = "ON_DEMAND"
  description = "The capacity type for the default managed node group."
}

## Security Group
variable "db_security_group_name" {
  type        = string
  default     = "tower_db_security_group"
  description = "The name of the security group for the database."
}

variable "redis_security_group_name" {
  type        = string
  default     = "tower_redis_security_group"
  description = "The name of the security group for Redis."
}

variable "tower_irsa_role_name" {
  type = string
  default = "tower-irsa-role"
  description = "The name of the IAM role for IRSA."
}

variable "tower_irsa_iam_policy_name" {
  type = string
  description = "The name of the IAM policy for IRSA."
  default = "tower-irsa-iam-policy"
}

## Database

variable "database_identifier" {
  type        = string
  default     = "tower"
  description = "The identifier for the database."
}

variable "redis_cluster_name" {
  type        = string
  default     = "tower"
  description = "The name of the Redis cluster."
}

variable "db_engine_version" {
  type        = string
  default     = "5.7"
  description = "The version of the database engine."
}

variable "db_instance_class" {
  type        = string
  default     = "db.r5.xlarge"
  description = "The instance class for the database."
}

variable "db_allocated_storage" {
  type        = number
  default     = 10
  description = "The allocated storage size for the database."
}

variable "db_name" {
  type        = string
  default     = "tower"
  description = "The name of the database."
}

variable "db_username" {
  type        = string
  default     = "tower"
  description = "The username for the database."
}

variable "db_password" {
  type        = string
  default     = "my_db_password"
  description = "Password for the master DB user. Note that this may show up in logs, and it will be stored in the state file. The password provided will not be used if `manage_master_user_password` is set to true."
}

variable "db_port" {
  type        = string
  default     = "3306"
  description = "The port for the database."
}

variable "db_iam_database_authentication_enabled" {
  type        = bool
  default     = false
  description = "Determines whether IAM database authentication is enabled for the database."
}

variable "db_maintenance_window" {
  type        = string
  default     = "Mon:00:00-Mon:03:00"
  description = "The maintenance window for the database."
}

variable "db_backup_window" {
  type        = string
  default     = "03:00-06:00"
  description = "The backup window for the database."
}

## DB Parameters
variable "db_parameters" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "The list of database parameters."
  default = [
    {
      name  = "character_set_client"
      value = "utf8mb4"
    },
    {
      name  = "character_set_server"
      value = "utf8mb4"
    }
  ]
}

## DB Options
variable "db_options" {
  type = list(object({
    option_name = string
    option_settings = list(object({
      name  = string
      value = string
    }))
  }))
  description = "The list of database options."
  default = [
    {
      option_name = "MARIADB_AUDIT_PLUGIN"

      option_settings = [
        {
          name  = "SERVER_AUDIT_EVENTS"
          value = "CONNECT"
        },
        {
          name  = "SERVER_AUDIT_FILE_ROTATIONS"
          value = "37"
        },
      ]
    },
  ]
}


variable "db_monitoring_interval" {
  type        = string
  default     = "0"
  description = "The monitoring interval for the database."
}

variable "db_monitoring_role_name" {
  type        = string
  default     = "TowerRDSMonitoringRole"
  description = "The name of the IAM role used for database monitoring."
}

variable "db_create_monitoring_role" {
  type        = bool
  default     = false
  description = "Determines whether the monitoring role should be created."
}

variable "db_family" {
  type        = string
  default     = "mysql5.7"
  description = "The family of the database engine."
}

variable "db_major_engine_version" {
  type        = string
  default     = "5.7"
  description = "The major version of the database engine."
}

variable "db_deletion_protection" {
  type        = bool
  default     = false
  description = "Determines whether deletion protection is enabled for the database."
}

## Redis MemoryDB Cluster

## Redis Engine Version
variable "redis_engine_version" {
  type        = string
  description = "The version of the Redis engine."
  default     = "6.2"
}

## Redis Auto Minor Version Upgrade
variable "redis_auto_minor_version_upgrade" {
  type        = bool
  description = "Determines whether automatic minor version upgrades are enabled for Redis."
  default     = false
}

## Redis Node Type
variable "redis_node_type" {
  type        = string
  description = "The Redis node type."
  default     = "db.t4g.small"
}

## Redis Number of Shards
variable "redis_num_shards" {
  type        = number
  description = "The number of shards in the Redis cluster."
  default     = 2
}

## Redis Number of Replicas per Shard
variable "redis_num_replicas_per_shard" {
  type        = number
  description = "The number of replicas per shard in the Redis cluster."
  default     = 2
}

## Redis TLS Enabled
variable "redis_tls_enabled" {
  type        = bool
  description = "Determines whether TLS (Transport Layer Security) is enabled for Redis."
  default     = true
}

## Redis Maintenance Window
variable "redis_maintenance_window" {
  type        = string
  description = "The maintenance window for the Redis cluster."
  default     = "sun:23:00-mon:01:30"
}

## Redis Snapshot Retention Limit
variable "redis_snapshot_retention_limit" {
  type        = number
  description = "The number of days to retain Redis snapshots."
  default     = 7
}

## Redis Snapshot Window
variable "redis_snapshot_window" {
  type        = string
  description = "The window during which Redis snapshots are taken."
  default     = "05:00-09:00"
}

## Redis Users
variable "redis_users" {
  type = map(object({
    user_name     = string
    access_string = string
    passwords     = list(string)
    tags          = map(string)
  }))
  description = "A map of Redis user configurations."
  default = {
    admin = {
      user_name     = "tower_admin-user"
      access_string = "on ~* &* +@all"
      passwords     = ["YouShouldPickAStrongSecurePassword987!"]
      tags          = { User = "admin" }
    }
    readonly = {
      user_name     = "tower_readonly-user"
      access_string = "on ~* &* -@all +@read"
      passwords     = ["YouShouldPickAStrongSecurePassword123!"]
      tags          = { User = "readonly" }
    }
  }
}

## Redis Parameter Group
variable "redis_parameter_group_name" {
  type        = string
  description = "The name of the Redis parameter group."
  default     = "tower-param-group"
}

variable "redis_parameter_group_description" {
  type        = string
  description = "The description of the Redis parameter group."
  default     = "Tower MemoryDB parameter group"
}

variable "redis_parameter_group_family" {
  type        = string
  description = "The family of the Redis parameter group."
  default     = "memorydb_redis6"
}

variable "redis_parameter_group_parameters" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "A list of Redis parameter configurations."
  default = [
    {
      name  = "activedefrag"
      value = "yes"
    }
  ]
}

variable "redis_parameter_group_tags" {
  type        = map(string)
  description = "Tags to be applied to the Redis parameter group."
  default = {
    ParameterGroup = "custom"
  }
}

## Redis Subnet Group
variable "redis_create_subnet_group" {
  type        = bool
  description = "Determines whether to create a Redis subnet group."
  default     = true
}

variable "redis_subnet_group_name" {
  type        = string
  description = "The name of the Redis subnet group."
  default     = "tower-redis-subnetgroup"
}

variable "redis_subnet_group_description" {
  type        = string
  description = "The description of the Redis subnet group."
  default     = "Tower MemoryDB subnet group"
}
