# ------------------------------------------------------------------------------
# Module setup
# ------------------------------------------------------------------------------

terraform {
  backend "s3" {}
}

locals {
  environment = var.environment
  namespace   = var.namespace
  tags        = var.tags
  vpc         = var.vpc
  services    = var.services
}

provider "aws" {}

# ------------------------------------------------------------------------------
# Module configuration
# ------------------------------------------------------------------------------

data "aws_route53_zone" "this" {
  name = local.environment.project.domain_name
}

module "ecs_cluster" {
  source = "terraform-aws-modules/ecs/aws//modules/cluster"

  cluster_name = "${local.namespace}-ecs-cluster"

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 100
      }
    }
  }

  tags = local.tags
}

module "acm" {
  for_each = { for service in local.services : service.name => service }

  source = "terraform-aws-modules/acm/aws"

  zone_id = data.aws_route53_zone.this.id

  domain_name = local.environment.project.domain_name

  subject_alternative_names = [
    "*.${local.environment.project.domain_name}",
  ]

  validation_method = "DNS"

  tags = local.tags
}

module "load_balancer" {
  for_each = { for service in local.services : service.name => service }

  source = "terraform-aws-modules/alb/aws"

  name = each.key

  load_balancer_type = "network"

  internal = true

  vpc_id  = local.vpc.id
  subnets = local.vpc.private_subnets

  listeners = {
    https = {
      port            = 443
      protocol        = "TLS"
      ssl_policy      = "ELBSecurityPolicy-2016-08"
      certificate_arn = module.acm.acm_certificate_arn
      alpn_policy     = "HTTP2Only"
      forward = {
        target_group_key = "default"
      }
    }
  }

  target_groups = {
    default = {
      name             = each.key
      backend_protocol = "TCP"
      backend_port     = each.value.port
      target_type      = "ip"
      health_check = {
        enabled             = true
        interval            = 10
        path                = "/health"
        port                = each.value.port
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 10
        protocol            = "HTTP"
        matcher             = "200"
      }
    }
  }

  tags = local.tags
}

module "ecs_service" {
  for_each = { for service in local.services : service.name => service }

  source = "terraform-aws-modules/ecs/aws//modules/service"

  name        = each.key
  cluster_arn = module.ecs_cluster.arn

  cpu    = each.value.cpu
  memory = each.value.memory

  container_definitions = {
    for key, value in each.value.container_definitions : key => {
      cpu       = value.cpu
      memory    = value.memory
      essential = true
      image     = value.image
      port_mappings = [
        {
          name          = key
          containerPort = value.container_port
          hostPort      = value.host_port
          protocol      = "tcp"
        }
      ]
      environment = [
        for key, value in value.environment :
        {
          name  = key
          value = value
        }
      ]
      readonly_root_filesystem = value.readonly_root_filesystem
    }
  }

  load_balancer = {
    service = {
      target_group_arn = element(module.load_balancer[each.key].target_group_arns, 0)
      container_name   = each.value.ingress
      container_port   = each.value.port
    }
  }

  subnet_ids = local.vpc.private_subnets

  security_group_rules = {
    ingress_nlb = {
      type        = "ingress"
      from_port   = each.value.port
      to_port     = each.value.port
      protocol    = "tcp"
      cidr_blocks = local.vpc.private_subnets_cidr_blocks
      description = "Service port"
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tasks_iam_role_statements = each.value.task_iam_policy_statements

  tags = local.tags
}
