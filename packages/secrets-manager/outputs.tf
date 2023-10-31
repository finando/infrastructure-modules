output "secret_id" {
  description = "ARN that identifies the secret"
  value       = { for secret in local.secrets : secret.name => aws_secretsmanager_secret.secret[secret.name].id }
}

output "secret_arn" {
  description = "ARN that identifies the secret"
  value       = { for secret in local.secrets : secret.name => aws_secretsmanager_secret.secret[secret.name].arn }
}

output "secret_name" {
  description = "Name of the secret"
  value       = { for secret in local.secrets : secret.name => aws_secretsmanager_secret.secret[secret.name].name }
}
