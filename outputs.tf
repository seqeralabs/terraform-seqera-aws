output "database_url" {
  value       = try(module.db[0].db_instance_address, null)
  description = "Endpoint address for the primary RDS database instance."
}

output "redis_url" {
  value       = try(module.memory_db[0].cluster_endpoint_address, null)
  description = "Endpoint address for the Redis cluster. If not available, returns null."
}

output "seqera_irsa_role_name" {
  value       = try(module.seqera_irsa[0].iam_role_name, null)
  description = "IAM role name associated with Seqera IRSA (IAM Roles for Service Accounts)."
}
