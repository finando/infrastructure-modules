# ------------------------------------------------------------------------------
# Module setup
# ------------------------------------------------------------------------------

terraform {
  backend "s3" {}
}

locals {
  environment  = var.environment
  namespace    = var.namespace
  tags         = var.tags
  vpc          = var.vpc
  api_gateways = var.api_gateways
}

provider "aws" {}

# ------------------------------------------------------------------------------
# Module configuration
# ------------------------------------------------------------------------------

data "aws_route53_zone" "this" {
  name = local.environment.project.domain_name
}

module "acm" {
  for_each = { for api_gateway in local.api_gateways : api_gateway.name => api_gateway }

  source = "terraform-aws-modules/acm/aws"

  zone_id = data.aws_route53_zone.this.zone_id

  domain_name = each.value.domain_name

  subject_alternative_names = [
    "*.${each.value.domain_name}",
  ]

  validation_method = "DNS"

  tags = local.tags
}

module "security_group" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "api-gateway-security-group"
  description = "API Gateway security group"

  vpc_id = local.vpc.id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["https-443-tcp"]

  egress_rules = ["all-all"]
}

module "api_gateway" {
  for_each = { for api_gateway in local.api_gateways : api_gateway.name => api_gateway }

  source = "terraform-aws-modules/apigateway-v2/aws"

  name          = "${local.namespace}-${each.value.name}"
  description   = "HTTP API Gateway for ${each.value.domain_name}"
  protocol_type = "HTTP"

  cors_configuration = {
    allow_headers = [
      "content-type",
      "x-amz-date",
      "authorization",
      "x-api-key",
      "x-amz-security-token",
      "x-amz-user-agent",
    ]
    allow_methods = ["*"]
    allow_origins = ["*"]
  }

  create_api_domain_name       = true
  disable_execute_api_endpoint = true
  domain_name                  = "www.${each.value.domain_name}"
  domain_name_certificate_arn  = module.acm[each.key].acm_certificate_arn

  integrations = each.value.integrations

  vpc_links = {
    for entry in toset([for integration in values(each.value.integrations) : integration if integration.connection_type == "VPC_LINK"]) : entry.vpc_link => {
      name               = entry.vpc_link
      subnet_ids         = local.vpc.private_subnets
      security_group_ids = [module.security_group.security_group_id]
    }
  }

  tags = local.tags
}
