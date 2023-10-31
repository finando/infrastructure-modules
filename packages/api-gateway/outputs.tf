output "api_gateway_api_id" {
  description = "The API identifier"
  value       = { for api_gateway in local.api_gateways : api_gateway.name => module.api_gateway[api_gateway.name].apigatewayv2_api_id }
}

output "api_gateway_api_endpoint" {
  description = "The URI of the API"
  value       = { for api_gateway in local.api_gateways : api_gateway.name => module.api_gateway[api_gateway.name].apigatewayv2_api_api_endpoint }
}

output "api_gateway_vpc_link_arn" {
  description = "The ARN of the VPC Link"
  value       = { for api_gateway in local.api_gateways : api_gateway.name => module.api_gateway[api_gateway.name].apigatewayv2_vpc_link_arn }
}

output "api_gateway_vpc_link_id" {
  description = "The identifier of the VPC Link"
  value       = { for api_gateway in local.api_gateways : api_gateway.name => module.api_gateway[api_gateway.name].apigatewayv2_vpc_link_id }
}

output "api_gateway_domain_name_id" {
  description = "The domain name identifier"
  value       = { for api_gateway in local.api_gateways : api_gateway.name => module.api_gateway[api_gateway.name].apigatewayv2_domain_name_id }
}

output "api_gateway_domain_name_arn" {
  description = "The ARN of the domain name"
  value       = { for api_gateway in local.api_gateways : api_gateway.name => module.api_gateway[api_gateway.name].apigatewayv2_domain_name_arn }
}

output "api_gateway_domain_name_hosted_zone_id" {
  description = "The Amazon Route 53 Hosted Zone ID of the endpoint"
  value       = { for api_gateway in local.api_gateways : api_gateway.name => module.api_gateway[api_gateway.name].apigatewayv2_domain_name_hosted_zone_id }
}

output "api_gateway_domain_name_configuration" {
  description = "The domain name configuration"
  value       = { for api_gateway in local.api_gateways : api_gateway.name => module.api_gateway[api_gateway.name].apigatewayv2_domain_name_configuration }
}

output "api_gateway_domain_name_target_domain_name" {
  description = "The target domain name"
  value       = { for api_gateway in local.api_gateways : api_gateway.name => module.api_gateway[api_gateway.name].apigatewayv2_domain_name_target_domain_name }
}
