output "database_url" {
  value = module.terraform-seqera-aws.database_url
}

output "redis_url" {
  value = module.terraform-seqera-aws.redis_url
}

output "ec2_instance_id" {
  value = module.terraform-seqera-aws.ec2_instance_id
}

output "ec2_instance_public_dns_name" {
  value = module.terraform-seqera-aws.ec2_instance_public_dns_name
}