output "ssm_parameter_ses_configuration_arn" {
  description = "The Amazon Resource Name (ARN) of the SES configuration parameter"
  value       = aws_ssm_parameter.ses_configuration.arn
}

output "ssm_parameter_ses_smtp_users_arn" {
  description = "The Amazon Resource Name (ARN) of the SES SMTP users parameter"
  value       = aws_ssm_parameter.ses_smtp_users.arn
}
