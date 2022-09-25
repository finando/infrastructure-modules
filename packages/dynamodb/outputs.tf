output "oidc_provider_dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = module.oidc_provider_dynamodb_table.dynamodb_table_arn
}

output "oidc_provider_dynamodb_table_id" {
  description = "ID of the DynamoDB table"
  value       = module.oidc_provider_dynamodb_table.dynamodb_table_id
}
