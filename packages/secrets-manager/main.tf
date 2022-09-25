# ------------------------------------------------------------------------------
# Module setup
# ------------------------------------------------------------------------------

terraform {
  backend "s3" {}
}

locals {
  region       = var.region.name
  project_name = var.common.project.name
  environment  = var.environment.name
  namespace    = "${local.project_name}-${local.region}-${local.environment}"
  tags         = merge(var.account.tags, var.region.tags, var.environment.tags)
}

provider "aws" {}

# ------------------------------------------------------------------------------
# Module configuration
# ------------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "oidc_jwks_secret" {
  name = "${local.namespace}-oidc-jwks"

  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "oidc_jwks_secret_value" {
  secret_id     = aws_secretsmanager_secret.oidc_jwks_secret.id
  secret_string = var.oidc_jwks_secret
}

resource "aws_secretsmanager_secret" "oidc_cookie_keys_secret" {
  name = "${local.namespace}-oidc-cookie-keys"

  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "oidc_cookie_keys_secret_value" {
  secret_id     = aws_secretsmanager_secret.oidc_cookie_keys_secret.id
  secret_string = var.oidc_cookie_keys_secret
}
