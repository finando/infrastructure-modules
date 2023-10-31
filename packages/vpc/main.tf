# ------------------------------------------------------------------------------
# Module setup
# ------------------------------------------------------------------------------

terraform {
  backend "s3" {}
}

locals {
  namespace = var.namespace
  tags      = var.tags
  cidr      = var.cidr
  azs       = slice(data.aws_availability_zones.this.names, 0, 3)
}

provider "aws" {}

# ------------------------------------------------------------------------------
# Module configuration
# ------------------------------------------------------------------------------

data "aws_availability_zones" "this" {}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${local.namespace}-vpc"

  azs = local.azs

  cidr = local.cidr

  public_subnets   = [for k, v in local.azs : cidrsubnet(local.cidr, 8, k)]
  private_subnets  = [for k, v in local.azs : cidrsubnet(local.cidr, 8, k + 4)]
  database_subnets = [for k, v in local.azs : cidrsubnet(local.cidr, 8, k + 8)]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = local.tags
}

module "vpc_endpoints" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"

  vpc_id = module.vpc.vpc_id

  create_security_group      = true
  security_group_name_prefix = "${local.namespace}-vpc-endpoint-"
  security_group_description = "VPC endpoint security group"
  security_group_rules = {
    ingress_https = {
      description = "HTTPS from VPC"
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
  }

  endpoints = {
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
      tags            = merge(local.tags, { Name = "s3-vpc-endpoint" })
    },
    dynamodb = {
      service         = "dynamodb"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
      tags            = merge(local.tags, { Name = "dynamodb-vpc-endpoint" })
    },
    secretsmanager = {
      service             = "secretsmanager"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags                = merge(local.tags, { Name = "secretsmanager-vpc-endpoint" })
    }
    ecr_dkr = {
      service             = "ecr.dkr"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags                = merge(local.tags, { Name = "ecr.dkr-vpc-endpoint" })
    },
    ecr_api = {
      service             = "ecr.api"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags                = merge(local.tags, { Name = "ecr.api-vpc-endpoint" })
    },
    logs = {
      service             = "logs"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags                = merge(local.tags, { Name = "logs-vpc-endpoint" })
    },
  }

  tags = local.tags
}
