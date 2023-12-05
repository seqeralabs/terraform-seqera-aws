## -- Complete Example for Public EC2 instance -- ##
module "terraform-seqera-aws" {
  source = "../../"
  region  = "eu-west-2"

  ## VPC
  vpc_name = "seqera-vpc"

  ## EKS Cluster Configurations
  create_eks_cluster = false

  ## EC2 Instance
  create_ec2_instance = true
  enable_ec2_instance_session_manager_access = false
  create_ec2_instance_local_key_pair = true
  create_ec2_public_instance = true

  create_redis_cluster = true
  db_root_password = "password25"
  db_app_password  = "password"
  create_db_cluster = true

  default_tags = {
    Environment = "development"
    ManagedBy   = "Terraform"
    Product     = "Seqera"
    CreatedBy   = "DevOps"
  }
}
