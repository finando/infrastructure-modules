# ------------------------------------------------------------------------------
# Module setup
# ------------------------------------------------------------------------------

terraform {
  backend "s3" {}
}

locals {
  region                  = var.region.name
  project_name            = var.common.project.name
  environment             = var.environment.name
  domain_name             = var.common.project.domain_name
  environment_domain_name = local.environment == "production" ? local.domain_name : "${local.environment}.${local.domain_name}"
  namespace               = "${local.project_name}-${local.region}-${local.environment}"
  static_website_s3_buckets = [
    {
      name   = "sso-web"
      domain = local.environment_domain_name
    }
  ]
  tags = merge(var.account.tags, var.region.tags, var.environment.tags)
}

provider "aws" {}

provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}

# ------------------------------------------------------------------------------
# Module configuration
# ------------------------------------------------------------------------------

data "aws_route53_zone" "route53_zone" {
  name = local.environment_domain_name
}

data "aws_acm_certificate" "acm_certificate" {
  domain   = local.environment_domain_name
  types    = ["AMAZON_ISSUED"]
  provider = aws.virginia
}

data "aws_iam_policy_document" "s3_bucket_policy_static_www_website" {
  for_each = { for bucket in local.static_website_s3_buckets : bucket.name => bucket }

  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = ["s3:GetObject"]

    resources = [
      "${module.s3_bucket_static_www_website[each.key].s3_bucket_arn}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [module.cloudfront_static_www_website[each.key].cloudfront_distribution_arn]
    }
  }
}

module "s3_bucket_static_www_website" {
  for_each = { for bucket in local.static_website_s3_buckets : bucket.name => bucket }

  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "${local.namespace}-www-${each.value.name}"

  acl = "private"

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

module "s3_bucket_static_apex_website" {
  for_each = { for bucket in local.static_website_s3_buckets : bucket.name => bucket }

  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "${local.namespace}-apex-${each.value.name}"

  acl = "private"

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
      host_name = "www.${each.value.domain}"
    }
  }

  tags = local.tags
}

resource "aws_s3_bucket_policy" "s3_bucket_policy" {
  for_each = { for bucket in local.static_website_s3_buckets : bucket.name => bucket }

  bucket = module.s3_bucket_static_www_website[each.key].s3_bucket_id
  policy = data.aws_iam_policy_document.s3_bucket_policy_static_www_website[each.key].json
}

resource "aws_cloudfront_origin_access_control" "default" {
  name                              = "${local.namespace}-origin-access-control"
  description                       = ""
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

module "cloudfront_static_www_website" {
  for_each = { for bucket in local.static_website_s3_buckets : bucket.name => bucket }

  source = "terraform-aws-modules/cloudfront/aws"

  aliases         = ["www.${each.value.domain}"]
  enabled         = true
  is_ipv6_enabled = true
  comment         = "${local.namespace}-${each.value.name}-www-cloudfront-distribution"
  price_class     = "PriceClass_100"

  default_root_object = "index.html"

  ordered_cache_behavior = [
    {
      path_pattern = "/index.html"

      allowed_methods = [
        "GET",
        "HEAD",
        "OPTIONS"
      ]
      cached_methods = [
        "GET",
        "HEAD"
      ]

      target_origin_id       = module.s3_bucket_static_www_website[each.key].s3_bucket_id
      viewer_protocol_policy = "redirect-to-https"
      compress               = true

      min_ttl     = 0
      default_ttl = 0
      max_ttl     = 0

      # CORS-and-SecurityHeadersPolicy ID (see https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-response-headers-policies.html)
      response_headers_policy_id = "e61eb60c-9c35-4d20-a928-2b84e02af89c"
    },
    {
      path_pattern = "/redirect.html"

      allowed_methods = [
        "GET",
        "HEAD",
        "OPTIONS"
      ]
      cached_methods = [
        "GET",
        "HEAD"
      ]

      target_origin_id       = module.s3_bucket_static_www_website[each.key].s3_bucket_id
      viewer_protocol_policy = "redirect-to-https"
      compress               = true

      min_ttl     = 0
      default_ttl = 0
      max_ttl     = 0

      # CORS-and-SecurityHeadersPolicy ID (see https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-response-headers-policies.html)
      response_headers_policy_id = "e61eb60c-9c35-4d20-a928-2b84e02af89c"
    },
    {
      path_pattern = "/favicon.svg"

      allowed_methods = [
        "GET",
        "HEAD",
        "OPTIONS"
      ]
      cached_methods = [
        "GET",
        "HEAD"
      ]

      target_origin_id       = module.s3_bucket_static_www_website[each.key].s3_bucket_id
      viewer_protocol_policy = "redirect-to-https"
      compress               = true

      min_ttl     = 0
      default_ttl = 0
      max_ttl     = 0

      # CORS-and-SecurityHeadersPolicy ID (see https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-response-headers-policies.html)
      response_headers_policy_id = "e61eb60c-9c35-4d20-a928-2b84e02af89c"
    },
    {
      path_pattern = "/sitemap.xml"

      allowed_methods = [
        "GET",
        "HEAD",
        "OPTIONS"
      ]
      cached_methods = [
        "GET",
        "HEAD"
      ]

      target_origin_id       = module.s3_bucket_static_www_website[each.key].s3_bucket_id
      viewer_protocol_policy = "redirect-to-https"
      compress               = true

      min_ttl     = 0
      default_ttl = 0
      max_ttl     = 0

      # CORS-and-SecurityHeadersPolicy ID (see https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-response-headers-policies.html)
      response_headers_policy_id = "e61eb60c-9c35-4d20-a928-2b84e02af89c"
    },
    {
      path_pattern = "/"

      allowed_methods = [
        "GET",
        "HEAD",
        "OPTIONS"
      ]
      cached_methods = [
        "GET",
        "HEAD"
      ]

      target_origin_id       = module.s3_bucket_static_www_website[each.key].s3_bucket_id
      viewer_protocol_policy = "redirect-to-https"
      compress               = true

      min_ttl     = 0
      default_ttl = 0
      max_ttl     = 0

      # CORS-and-SecurityHeadersPolicy ID (see https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-response-headers-policies.html)
      response_headers_policy_id = "e61eb60c-9c35-4d20-a928-2b84e02af89c"
    }
  ]

  default_cache_behavior = {
    allowed_methods = [
      "GET",
      "HEAD",
      "OPTIONS"
    ]
    cached_methods = [
      "GET",
      "HEAD"
    ]

    target_origin_id       = module.s3_bucket_static_www_website[each.key].s3_bucket_id
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400

    # CORS-and-SecurityHeadersPolicy ID (see https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-response-headers-policies.html)
    response_headers_policy_id = "e61eb60c-9c35-4d20-a928-2b84e02af89c"
  }

  custom_error_response = [
    {
      error_code         = 404
      response_code      = 200
      response_page_path = "/redirect.html"
    },
    {
      error_code         = 403
      response_code      = 200
      response_page_path = "/redirect.html"
    }
  ]

  viewer_certificate = {
    acm_certificate_arn = data.aws_acm_certificate.acm_certificate.arn
    ssl_support_method  = "sni-only"
  }

  geo_restriction = {
    restriction_type = "none"
  }

  origin = {
    s3 = {
      domain_name              = module.s3_bucket_static_www_website[each.key].s3_bucket_bucket_regional_domain_name
      origin_id                = module.s3_bucket_static_www_website[each.key].s3_bucket_id
      origin_access_control_id = aws_cloudfront_origin_access_control.default.id
    }
  }

  tags = local.tags
}

module "cloudfront_static_apex_website" {
  for_each = { for bucket in local.static_website_s3_buckets : bucket.name => bucket }

  source = "terraform-aws-modules/cloudfront/aws"

  aliases         = [each.value.domain]
  enabled         = true
  is_ipv6_enabled = true
  comment         = "${local.namespace}-${each.value.name}-apex-cloudfront-distribution"
  price_class     = "PriceClass_100"

  default_cache_behavior = {
    allowed_methods = [
      "GET",
      "HEAD",
      "OPTIONS"
    ]
    cached_methods = [
      "GET",
      "HEAD"
    ]

    target_origin_id       = module.s3_bucket_static_apex_website[each.key].s3_bucket_id
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400

    # CORS-and-SecurityHeadersPolicy ID (see https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-response-headers-policies.html)
    response_headers_policy_id = "e61eb60c-9c35-4d20-a928-2b84e02af89c"
  }

  viewer_certificate = {
    acm_certificate_arn = data.aws_acm_certificate.acm_certificate.arn
    ssl_support_method  = "sni-only"
  }

  geo_restriction = {
    restriction_type = "none"
  }

  origin = {
    s3 = {
      domain_name = module.s3_bucket_static_apex_website[each.key].s3_bucket_website_endpoint
      origin_id   = module.s3_bucket_static_apex_website[each.key].s3_bucket_id

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

resource "aws_route53_record" "static_www_website_cloudfront_distribution_route53_record" {
  for_each = { for bucket in local.static_website_s3_buckets : bucket.name => bucket }

  zone_id = data.aws_route53_zone.route53_zone.zone_id
  name    = "www.${each.value.domain}"
  type    = "A"

  alias {
    name                   = module.cloudfront_static_www_website[each.key].cloudfront_distribution_domain_name
    zone_id                = module.cloudfront_static_www_website[each.key].cloudfront_distribution_hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "static_apex_website_cloudfront_distribution_route53_record" {
  for_each = { for bucket in local.static_website_s3_buckets : bucket.name => bucket }

  zone_id = data.aws_route53_zone.route53_zone.zone_id
  name    = each.value.domain
  type    = "A"

  alias {
    name                   = module.cloudfront_static_apex_website[each.key].cloudfront_distribution_domain_name
    zone_id                = module.cloudfront_static_apex_website[each.key].cloudfront_distribution_hosted_zone_id
    evaluate_target_health = true
  }
}
