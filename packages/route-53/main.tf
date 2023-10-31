# ------------------------------------------------------------------------------
# Module setup
# ------------------------------------------------------------------------------

terraform {
  backend "s3" {}
}

locals {
  environment             = var.environment.name
  root_domain_name        = var.common.project.domain_name
  environment_domain_name = var.environment.project.domain_name
  dns_records             = var.dns_records
  tags                    = var.tags
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
  name = local.root_domain_name
}

resource "aws_route53_record" "subdomain_ns_record" {
  count = local.environment == "production" ? 0 : 1

  zone_id = data.aws_route53_zone.production_route53_zone.zone_id
  name    = aws_route53_zone.this.name
  type    = "NS"
  ttl     = "600"
  records = aws_route53_zone.this.name_servers
}

resource "aws_route53_record" "dns_records" {
  for_each = local.dns_records

  zone_id = data.aws_route53_zone.production_route53_zone.zone_id
  name    = "${each.value.prefix}.${data.aws_route53_zone.production_route53_zone.name}"
  type    = each.value.type
  ttl     = each.value.ttl
  records = each.value.records
}
