# ------------------------------------------------------------------------------
# Module setup
# ------------------------------------------------------------------------------

terraform {
  backend "s3" {}
}

locals {
  domain_name = var.common.project.domain_name
  tags        = merge(var.account.tags, var.region.tags, var.environment.tags)
}

provider "aws" {}

# ------------------------------------------------------------------------------
# Module configuration
# ------------------------------------------------------------------------------

resource "aws_route53_zone" "this" {
  name = local.domain_name

  tags = local.tags
}
