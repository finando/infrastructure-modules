# ------------------------------------------------------------------------------
# Module setup
# ------------------------------------------------------------------------------

terraform {
  backend "s3" {}
}

locals {
  namespace = var.namespace
  tags      = var.tags
}

provider "aws" {}

# ------------------------------------------------------------------------------
# Module configuration
# ------------------------------------------------------------------------------

module "oidc_provider_dynamodb_table" {
  source = "terraform-aws-modules/dynamodb-table/aws"

  name        = "${local.namespace}-oidc-provider"
  hash_key    = "id"
  table_class = "STANDARD"

  attributes = [
    {
      name = "id"
      type = "S"
    }
  ]

  ttl_enabled        = true
  ttl_attribute_name = "expiresAt"

  tags = local.tags
}
