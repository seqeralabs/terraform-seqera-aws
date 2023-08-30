output "database_url" {
  value       = module.db.db_instance_address
  description = "Database URL"
}

output "redis_url" {
  value       = module.memory_db.cluster_endpoint_address
  description = "Redis URL"
}

output "seqera_irsa_role_name" {
  value       = module.seqera_irsa.iam_role_name
  description = "Seqera IRSA Role Name"
}