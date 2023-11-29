## -- Complete Example for EKS cluster -- ##
module "terraform-seqera-module" {
  source = "../../"
  region  = "eu-west-2"

  ## VPC
  vpc_name = "seqera-vpc"

  ## EKS Cluster Configurations
  create_eks_cluster = true
  cluster_name    = "seqera-terraform-aws"
  cluster_version = "1.27"
  seqera_managed_node_group_defaults_instance_types = ["t3.medium"]
  seqera_managed_node_group_defaults_capacity_type = "ON_DEMAND"
  eks_aws_auth_roles = [ 
    "arn:aws:iam::123456789102:role/myrole"
  ]

  ## EC2 Instance
  create_ec2_instance = false

  ## EKS AWS Auth Users
  eks_aws_auth_users = [
    "arn:aws:iam::123456789102:user/myuser"
  ]

  ## EKS Seqera Managed Node Group Max Size
  seqera_managed_node_group_max_size = 10

  enable_aws_ebs_csi_driver = true
  enable_aws_loadbalancer_controller = true
  enable_aws_cluster_autoscaler = true
  enable_aws_efs_csi_driver = true

  create_redis_cluster = true
  create_db_cluster = true

  create_seqera_service_account = true

  default_tags = {
    Environment = "development"
    ManagedBy   = "Terraform"
    Product     = "Seqera"
    CreatedBy   = "DevOps"
  }
}