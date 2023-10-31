# ------------------------------------------------------------------------------
# Module setup
# ------------------------------------------------------------------------------

terraform {
  backend "s3" {}
}

locals {
  namespace = var.namespace
  tags      = var.tags
  secrets   = var.secrets
}

provider "aws" {}

# ------------------------------------------------------------------------------
# Module configuration
# ------------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "secret" {
  for_each = { for secret in local.secrets : secret.name => secret }

  name = "${local.namespace}-${each.key}"

  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "secret_value" {
  for_each = { for secret in local.secrets : secret.name => secret.value }

  secret_id     = aws_secretsmanager_secret.secret[each.key].id
  secret_string = each.value
}
