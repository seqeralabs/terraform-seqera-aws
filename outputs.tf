output "tower_irsa_iam_role_name" {
  description = "The name of the IAM role created for the Tower service account"
  value       = try(module.eks.aws_iam_role.this[0].name, null)
}