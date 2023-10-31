# ------------------------------------------------------------------------------
# Module setup
# ------------------------------------------------------------------------------

terraform {
  backend "s3" {}
}

locals {
  namespace    = var.namespace
  repositories = var.repositories
  tags         = var.tags
}

provider "aws" {}

# ------------------------------------------------------------------------------
# Module configuration
# ------------------------------------------------------------------------------

data "aws_iam_user" "alzak" {
  user_name = "alzak"
}

data "aws_iam_user" "github" {
  user_name = "github"
}

module "ecr" {
  source = "terraform-aws-modules/ecr/aws"

  for_each = local.repositories

  repository_name = "${local.namespace}-${each.value}"
  repository_type = "private"

  repository_image_tag_mutability = "MUTABLE"

  repository_read_access_arns = [
    data.aws_iam_user.alzak.arn,
    data.aws_iam_user.github.arn
  ]
  repository_read_write_access_arns = [
    data.aws_iam_user.alzak.arn,
    data.aws_iam_user.github.arn
  ]

  create_lifecycle_policy = false

  tags = local.tags
}

data "aws_ecr_image" "this" {
  for_each = local.repositories

  repository_name = "${local.namespace}-${each.value}"
  image_tag       = "latest"
}
