## -- Complete Example for EKS cluster -- ##
module "terraform-seqera-aws" {
  source = "../../"
  region  = "eu-west-2"

  ## VPC
  vpc_name = "seqera-vpc"

  ## EKS Cluster Configurations
  create_eks_cluster = true
  cluster_name    = "seqera-terraform-aws"
  cluster_version = "1.27"

  ## EC2 Instance
  create_ec2_instance = false

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