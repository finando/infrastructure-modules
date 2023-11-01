output "ssm_parameter_arn" {
  description = "SSM parameter ARN"
  value       = { for key, value in nonsensitive(local.ssm_parameters) : key => aws_ssm_parameter.this[key].arn }
}

output "ssm_parameter_name" {
  description = "SSM parameter name"
  value       = { for key, value in nonsensitive(local.ssm_parameters) : key => aws_ssm_parameter.this[key].name }
}
