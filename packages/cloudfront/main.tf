# ------------------------------------------------------------------------------
# Module setup
# ------------------------------------------------------------------------------

terraform {
  backend "s3" {}
}

locals {
  environment              = var.environment
  namespace                = var.namespace
  tags                     = var.tags
  cloudfront_distributions = var.cloudfront_distributions
  allowed_methods = {
    API_GATEWAY = [
      "GET",
      "HEAD",
      "OPTIONS",
      "PUT",
      "POST",
      "PATCH",
      "DELETE",
    ]
    S3 = [
      "GET",
      "HEAD",
      "OPTIONS",
    ]
  }
  cached_methods = {
    API_GATEWAY = [
      "GET",
      "HEAD",
    ]
    S3 = [
      "GET",
      "HEAD",
    ]
  }
  cache_policy_id = {
    API_GATEWAY = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # CachingDisabled (see https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-cache-policies.html#managed-cache-policy-caching-disabled)
    S3          = "658327ea-f89d-4fab-a63d-7e88639e58f6" # CachingOptimized (see https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-cache-policies.html#managed-cache-caching-optimized)
  }
  origin_request_policy_id = {
    API_GATEWAY = "216adef6-5c7f-47e4-b989-5492eafa07d3" # AllViewer (see https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-origin-request-policies.html#managed-origin-request-policy-all-viewer)
    S3          = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf" # CORS-S3Origin (see https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-origin-request-policies.html#managed-origin-request-policy-cors-s3)
  }
  response_headers_policy_id = {
    API_GATEWAY = "e61eb60c-9c35-4d20-a928-2b84e02af89c" # CORS-and-SecurityHeadersPolicy ID (see https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-response-headers-policies.html)
    S3          = "e61eb60c-9c35-4d20-a928-2b84e02af89c" # CORS-and-SecurityHeadersPolicy ID (see https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-response-headers-policies.html)
  }
}

provider "aws" {}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# ------------------------------------------------------------------------------
# Module configuration
# ------------------------------------------------------------------------------

data "aws_route53_zone" "this" {
  name = local.environment.project.domain_name
}

data "aws_iam_policy_document" "s3_bucket_policy" {
  for_each = { for cloudfront_distribution in local.cloudfront_distributions : cloudfront_distribution.name => distinct(try(cloudfront_distribution.s3_origins[*].s3_bucket_arn, [])) }

  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = ["s3:GetObject"]

    resources = [for s3_bucket_arn in each.value : "${s3_bucket_arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [module.cloudfront_www[each.key].cloudfront_distribution_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "s3_bucket_policy" {
  for_each = {
    for entry in distinct(flatten([
      for cloudfront_distribution in local.cloudfront_distributions : [
        for s3_bucket_id in distinct(try(cloudfront_distribution.s3_origins[*].s3_bucket_id, [])) : {
          key   = cloudfront_distribution.name
          value = s3_bucket_id
        }
        if length(s3_bucket_id) > 0
      ]
    ])) : entry.key => entry.value
  }

  bucket = each.value
  policy = data.aws_iam_policy_document.s3_bucket_policy[each.key].json
}

module "acm" {
  for_each = { for cloudfront_distribution in local.cloudfront_distributions : cloudfront_distribution.name => cloudfront_distribution }

  source = "terraform-aws-modules/acm/aws"

  providers = {
    aws = aws.us_east_1
  }

  zone_id = data.aws_route53_zone.this.zone_id

  domain_name = each.value.domain_name

  subject_alternative_names = [
    "*.${each.value.domain_name}",
  ]

  validation_method = "DNS"

  tags = local.tags
}

resource "aws_cloudfront_function" "rewrite_request_url" {
  name    = "${local.namespace}-rewrite-request-url"
  runtime = "cloudfront-js-1.0"
  code    = file("${path.module}/functions/rewrite-request-url.js")
}

module "s3_bucket_apex_redirector" {
  for_each = { for cloudfront_distribution in local.cloudfront_distributions : cloudfront_distribution.name => cloudfront_distribution }

  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "${local.namespace}-${each.value.name}-redirector"

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

  website = {
    redirect_all_requests_to = {
      protocol  = "https"
      host_name = "www.${each.value.domain_name}"
    }
  }

  tags = local.tags
}

module "cloudfront_www" {
  for_each = { for cloudfront_distribution in local.cloudfront_distributions : cloudfront_distribution.name => cloudfront_distribution }

  source = "terraform-aws-modules/cloudfront/aws"

  aliases         = ["www.${each.value.domain_name}"]
  enabled         = true
  is_ipv6_enabled = true
  comment         = "${local.namespace}-${each.value.name}-www-cloudfront-distribution"
  price_class     = "PriceClass_100"

  create_origin_access_control = true

  origin_access_control = {
    ("${each.value.name}-s3-oac") = {
      description      = ""
      origin_type      = "s3"
      signing_behavior = "always"
      signing_protocol = "sigv4"
    }
  }

  ordered_cache_behavior = tolist([
    for index, cache_behaviour in each.value.cache_behaviours : {
      path_pattern = cache_behaviour.path

      allowed_methods = local.allowed_methods[cache_behaviour.type]
      cached_methods  = local.cached_methods[cache_behaviour.type]

      compress               = true
      viewer_protocol_policy = "redirect-to-https"
      use_forwarded_values   = false

      min_ttl     = cache_behaviour.disable_cache ? 0 : null
      default_ttl = cache_behaviour.disable_cache ? 0 : null
      max_ttl     = cache_behaviour.disable_cache ? 0 : null

      cache_policy_id            = cache_behaviour.disable_cache ? "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" : local.cache_policy_id[cache_behaviour.type]
      origin_request_policy_id   = local.origin_request_policy_id[cache_behaviour.type]
      response_headers_policy_id = local.response_headers_policy_id[cache_behaviour.type]

      function_association = cache_behaviour.rewrite_request_url ? {
        viewer-request = {
          function_arn = aws_cloudfront_function.rewrite_request_url.arn
        }
      } : {}

      target_origin_id = cache_behaviour.target_origin_id
    } if cache_behaviour.path != null && cache_behaviour.path != "*"
  ])

  default_cache_behavior = element(tolist([
    for index, cache_behaviour in each.value.cache_behaviours : {
      allowed_methods = local.allowed_methods[cache_behaviour.type]
      cached_methods  = local.cached_methods[cache_behaviour.type]

      compress               = true
      viewer_protocol_policy = "redirect-to-https"
      use_forwarded_values   = false

      min_ttl     = cache_behaviour.disable_cache ? 0 : null
      default_ttl = cache_behaviour.disable_cache ? 0 : null
      max_ttl     = cache_behaviour.disable_cache ? 0 : null

      cache_policy_id            = cache_behaviour.disable_cache ? "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" : local.cache_policy_id[cache_behaviour.type]
      origin_request_policy_id   = local.origin_request_policy_id[cache_behaviour.type]
      response_headers_policy_id = local.response_headers_policy_id[cache_behaviour.type]

      function_association = cache_behaviour.rewrite_request_url ? {
        viewer-request = {
          function_arn = aws_cloudfront_function.rewrite_request_url.arn
        }
      } : {}

      target_origin_id = cache_behaviour.target_origin_id
    } if cache_behaviour.path == null || cache_behaviour.path == "*"
  ]), 0)

  custom_error_response = each.value.custom_error_response

  viewer_certificate = {
    acm_certificate_arn = module.acm[each.key].acm_certificate_arn
    ssl_support_method  = "sni-only"
  }

  geo_restriction = {
    restriction_type = "none"
  }

  origin = merge(
    {
      for origin in try(each.value.api_gateway_origins, []) : origin.id => {
        domain_name = origin.domain_name
        custom_origin_config = {
          http_port              = 80
          https_port             = 443
          origin_protocol_policy = "https-only"
          origin_ssl_protocols   = ["TLSv1.2"]
        }
      }
      if origin != null
    },
    {
      for origin in try(each.value.s3_origins, []) : origin.id => {
        domain_name           = origin.domain_name
        origin_id             = origin.s3_bucket_id
        origin_access_control = "${each.value.name}-s3-oac"
      }
      if origin != null
    },
  )

  tags = local.tags
}

module "cloudfront_apex" {
  for_each = { for cloudfront_distribution in local.cloudfront_distributions : cloudfront_distribution.name => cloudfront_distribution }

  source = "terraform-aws-modules/cloudfront/aws"

  aliases         = [each.value.domain_name]
  enabled         = true
  is_ipv6_enabled = true
  comment         = "${local.namespace}-${each.value.name}-apex-cloudfront-distribution"
  price_class     = "PriceClass_100"

  default_cache_behavior = {
    allowed_methods = [
      "GET",
      "HEAD",
      "OPTIONS",
      "PUT",
      "POST",
      "PATCH",
      "DELETE",
    ]
    cached_methods = [
      "GET",
      "HEAD",
    ]

    compress               = true
    viewer_protocol_policy = "redirect-to-https"
    use_forwarded_values   = false

    cache_policy_id            = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # CachingDisabled (see https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-cache-policies.html#managed-cache-policy-caching-disabled)
    origin_request_policy_id   = "b689b0a8-53d0-40ab-baf2-68738e2966ac" # AllViewerExceptHostHeader (see https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-origin-request-policies.html#managed-origin-request-policy-all-viewer-except-host-header)
    response_headers_policy_id = "e61eb60c-9c35-4d20-a928-2b84e02af89c" # CORS-and-SecurityHeadersPolicy ID (see https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-response-headers-policies.html)

    target_origin_id = module.s3_bucket_apex_redirector[each.key].s3_bucket_id
  }

  viewer_certificate = {
    acm_certificate_arn = module.acm[each.key].acm_certificate_arn
    ssl_support_method  = "sni-only"
  }

  geo_restriction = {
    restriction_type = "none"
  }

  origin = {
    s3 = {
      origin_id   = module.s3_bucket_apex_redirector[each.key].s3_bucket_id
      domain_name = module.s3_bucket_apex_redirector[each.key].s3_bucket_website_endpoint
      custom_origin_config = {
        http_port              = "80"
        https_port             = "443"
        origin_protocol_policy = "http-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  tags = local.tags
}

resource "aws_route53_record" "www_api_gateway_route53_record" {
  for_each = { for cloudfront_distribution in local.cloudfront_distributions : cloudfront_distribution.name => cloudfront_distribution }

  zone_id = data.aws_route53_zone.this.zone_id
  name    = "www.${each.value.domain_name}"
  type    = "A"

  alias {
    name                   = module.cloudfront_www[each.key].cloudfront_distribution_domain_name
    zone_id                = module.cloudfront_www[each.key].cloudfront_distribution_hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "apex_api_gateway_route53_record" {
  for_each = { for cloudfront_distribution in local.cloudfront_distributions : cloudfront_distribution.name => cloudfront_distribution }

  zone_id = data.aws_route53_zone.this.zone_id
  name    = each.value.domain_name
  type    = "A"

  alias {
    name                   = module.cloudfront_apex[each.key].cloudfront_distribution_domain_name
    zone_id                = module.cloudfront_apex[each.key].cloudfront_distribution_hosted_zone_id
    evaluate_target_health = true
  }
}
