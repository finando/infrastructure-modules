output "repository_arn" {
  description = "Full ARN of the repository"
  value       = { for key, value in module.ecr : key => value.repository_arn }
}

output "repository_name" {
  description = "Full ARN of the repository"
  value       = { for key, value in module.ecr : key => "${local.namespace}-${key}" }
}

output "repository_registry_id" {
  description = "The registry ID where the repository was created"
  value       = { for key, value in module.ecr : key => value.repository_registry_id }
}

output "repository_url" {
  description = "The URL of the repository"
  value       = { for key, value in module.ecr : key => value.repository_url }
}

output "latest_image_tag_id" {
  description = "The ID of the latest image tag"
  value       = { for key, value in module.ecr : key => data.aws_ecr_image.this[key].id }
}
