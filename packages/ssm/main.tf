# ------------------------------------------------------------------------------
# Module setup
# ------------------------------------------------------------------------------

terraform {
  backend "s3" {}
}

locals {
  tags           = var.tags
  ssm_parameters = var.ssm_parameters
}

provider "aws" {}

# ------------------------------------------------------------------------------
# Module configuration
# ------------------------------------------------------------------------------

resource "aws_ssm_parameter" "this" {
  for_each = nonsensitive(local.ssm_parameters)

  name        = each.value.name
  description = each.value.description
  type        = each.value.type
  value       = each.value.value

  lifecycle {
    ignore_changes = [
      value
    ]
  }

  tags = local.tags
}
