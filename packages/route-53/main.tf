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

data "aws_route53_zone" "production_route53_zone" {
  name = local.domain_name
}

resource "aws_route53_record" "subdomain_ns_record" {
  count = local.environment == "production" ? 0 : 1

  zone_id = data.aws_route53_zone.production_route53_zone.zone_id
  name    = aws_route53_zone.this.name
  type    = "NS"
  ttl     = "600"
  records = aws_route53_zone.this.name_servers
}
