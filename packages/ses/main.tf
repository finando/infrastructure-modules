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
  from_email              = var.from_email
  forward_emails          = var.forward_emails
  tags                    = merge(var.account.tags, var.region.tags, var.environment.tags)
}

provider "aws" {}

# ------------------------------------------------------------------------------
# Module configuration
# ------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

data "aws_route53_zone" "this" {
  name = local.domain_name
}

resource "aws_ses_domain_identity" "this" {
  domain = local.environment_domain_name
}

resource "aws_ses_domain_dkim" "this" {
  domain = aws_ses_domain_identity.this.domain
}

resource "aws_ses_domain_mail_from" "this" {
  domain           = aws_ses_domain_identity.this.domain
  mail_from_domain = "email.${aws_ses_domain_identity.this.domain}"
}

resource "aws_route53_record" "ses_verification_record" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "_amazonses.${local.environment_domain_name}"
  type    = "TXT"
  ttl     = "600"
  records = [aws_ses_domain_identity.this.verification_token]
}

resource "aws_route53_record" "ses_dkim_record" {
  count   = 3
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "${element(aws_ses_domain_dkim.this.dkim_tokens, count.index)}._domainkey.${local.environment_domain_name}"
  type    = "CNAME"
  ttl     = "600"
  records = ["${element(aws_ses_domain_dkim.this.dkim_tokens, count.index)}.dkim.amazonses.com"]
}

resource "aws_route53_record" "ses_domain_mail_from_mx_record" {
  zone_id = data.aws_route53_zone.this.id
  name    = aws_ses_domain_mail_from.this.mail_from_domain
  type    = "MX"
  ttl     = "600"
  records = ["10 feedback-smtp.${local.region}.amazonses.com"]
}

resource "aws_route53_record" "ses_domain_mail_from_txt_record" {
  zone_id = data.aws_route53_zone.this.id
  name    = aws_ses_domain_mail_from.this.mail_from_domain
  type    = "TXT"
  ttl     = "600"
  records = ["v=spf1 include:amazonses.com -all"]
}

resource "aws_route53_record" "ses_inbound_mx_record" {
  zone_id = data.aws_route53_zone.this.id
  name    = aws_ses_domain_identity.this.id
  type    = "MX"
  ttl     = "600"
  records = ["10 inbound-smtp.${local.region}.amazonaws.com"]
}

resource "aws_ses_receipt_rule_set" "this" {
  rule_set_name = "${local.namespace}-receipt-rule-set"
}

resource "aws_ses_active_receipt_rule_set" "this" {
  rule_set_name = aws_ses_receipt_rule_set.this.rule_set_name
}

resource "aws_ses_receipt_rule" "this" {
  name          = "${local.namespace}-receipt-rule-store-and-forward"
  rule_set_name = aws_ses_receipt_rule_set.this.rule_set_name
  recipients    = keys(local.forward_emails)
  enabled       = true
  scan_enabled  = true

  s3_action {
    bucket_name = aws_s3_bucket.inbound_emails.bucket
    position    = 1
  }

  lambda_action {
    function_arn = module.aws_lambda_ses_email_forwarder.lambda_function_arn
    position     = 2
  }

  depends_on = [
    aws_ses_receipt_rule_set.this,
    aws_s3_bucket_policy.this
  ]
}

data "aws_iam_policy_document" "ses_write_to_s3_bucket" {
  statement {
    sid = "GiveSESPermissionToWriteEmail"

    effect = "Allow"

    principals {
      identifiers = ["ses.amazonaws.com"]
      type        = "Service"
    }

    actions = ["s3:PutObject"]

    resources = ["${aws_s3_bucket.inbound_emails.arn}/*"]

    condition {
      test     = "StringEquals"
      values   = [data.aws_caller_identity.current.account_id]
      variable = "aws:Referer"
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.inbound_emails.id
  policy = data.aws_iam_policy_document.ses_write_to_s3_bucket.json
}


resource "aws_s3_bucket" "inbound_emails" {
  bucket        = "${local.namespace}-inbound-emails"
  force_destroy = false

  tags = local.tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.inbound_emails.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_acl" "this" {
  bucket = aws_s3_bucket.inbound_emails.id
  acl    = "private"
}

module "aws_lambda_ses_email_forwarder" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "${local.namespace}-email-forwarder-lambda"
  description   = "AWS Lambda function for forwarding SES emails."
  runtime       = "nodejs16.x"
  handler       = "index.handler"

  source_path = [
    {
      path = "${path.module}/email-forwarder-lambda"
      commands = [
        "npm ci",
        "npm run build",
        "npm prune --production",
        "cp -R node_modules dist/node_modules",
        "cd dist",
        ":zip",
      ]
    }
  ]

  environment_variables = {
    FROM_EMAIL_ADDRESS = local.from_email
    BUCKET_NAME        = aws_s3_bucket.inbound_emails.bucket
    EMAIL_MAPPING      = jsonencode(local.forward_emails)
  }

  timeout = 10

  attach_policy_json = true
  policy_json        = data.aws_iam_policy_document.lambda_read_from_s3_bucket.json

  tags = local.tags
}

resource "aws_lambda_permission" "allow_lambda_execution_from_ses" {
  statement_id   = "AllowExecutionFromSES"
  action         = "lambda:InvokeFunction"
  function_name  = module.aws_lambda_ses_email_forwarder.lambda_function_name
  principal      = "ses.amazonaws.com"
  source_account = data.aws_caller_identity.current.account_id
}

data "aws_iam_policy_document" "lambda_read_from_s3_bucket" {
  statement {
    sid       = "GiveAWSLambdaPermissionToReadEmail"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.inbound_emails.arn}/*"]
  }

  statement {
    sid       = "GiveAWSLambdaPermissionToSendEmail"
    effect    = "Allow"
    actions   = ["ses:SendRawEmail"]
    resources = ["*"]
  }
}
