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
  repositories = var.repositories
  tags         = merge(var.account.tags, var.region.tags, var.environment.tags)
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
