output "database_url" {
  value = module.terraform-seqera-module.database_url
}

output "redis_url" {
  value = module.terraform-seqera-module.redis_url
}

output "ec2_instance_id" {
  value = module.terraform-seqera-module.ec2_instance_id
}

output "ec2_instance_public_dns_name" {
  value = module.terraform-seqera-module.ec2_instance_public_dns_name
}