output "user_pool_id" {
  description = "ID of the user pool"
  value       = aws_cognito_user_pool.this.id
}

output "user_pool_arn" {
  description = "ARN of the user pool"
  value       = aws_cognito_user_pool.this.arn
}

output "user_pool_endpoint" {
  description = "Endpoint name of the user pool"
  value       = aws_cognito_user_pool.this.endpoint
}

output "user_pool_client_id" {
  description = "ID of the user pool client"
  value       = aws_cognito_user_pool_client.this.id
}
