# ------------------------------------------------------------------------------
# Module setup
# ------------------------------------------------------------------------------

terraform {
  backend "s3" {}
}

locals {
  environment             = var.environment.name
  domain_name             = var.common.project.domain_name
  environment_domain_name = local.environment == "production" ? local.domain_name : "${local.environment}.${local.domain_name}"
  tags                    = merge(var.account.tags, var.region.tags, var.environment.tags)
}

provider "aws" {}

# ------------------------------------------------------------------------------
# Module configuration
# ------------------------------------------------------------------------------

resource "aws_route53_zone" "this" {
  name = local.environment_domain_name

  tags = local.tags
}
