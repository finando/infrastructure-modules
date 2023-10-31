# ------------------------------------------------------------------------------
# Module setup
# ------------------------------------------------------------------------------

terraform {
  backend "s3" {}
}

locals {
  domain_name = var.environment.project.domain_name
  namespace   = var.namespace
  tags        = var.tags
  s3_buckets  = var.s3_buckets
}

provider "aws" {}

# ------------------------------------------------------------------------------
# Module configuration
# ------------------------------------------------------------------------------

module "s3_bucket" {
  for_each = { for bucket in local.s3_buckets : bucket.name => bucket }

  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "${local.namespace}-${each.value.name}"

  acl = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = local.tags
}
