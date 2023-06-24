# ------------------------------------------------------------------------------
# Module setup
# ------------------------------------------------------------------------------

terraform {
  backend "s3" {}
}

locals {
  region                  = var.region.name
  project_name            = var.common.project.name
  environment             = var.environment.name
  domain_name             = var.common.project.domain_name
  environment_domain_name = local.environment == "production" ? local.domain_name : "${local.environment}.${local.domain_name}"
  namespace               = "${local.project_name}-${local.region}-${local.environment}"
  tags                    = merge(var.account.tags, var.region.tags, var.environment.tags)
}

provider "aws" {}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

# ------------------------------------------------------------------------------
# Module configuration
# ------------------------------------------------------------------------------

data "aws_route53_zone" "route53_zone" {
  name = local.environment_domain_name
}

module "acm" {
  source = "terraform-aws-modules/acm/aws"

  providers = {
    aws = aws.us-east-1
  }

  domain_name = local.environment_domain_name
  zone_id     = data.aws_route53_zone.route53_zone.zone_id

  subject_alternative_names = [
    "*.${local.environment_domain_name}",
    "*.id.${local.environment_domain_name}",
  ]

  wait_for_validation = true

  tags = local.tags
}
