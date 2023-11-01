# ------------------------------------------------------------------------------
# Module setup
# ------------------------------------------------------------------------------

terraform {
  backend "s3" {}
}

locals {
  region                  = var.region.name
  root_domain_name        = var.common.project.domain_name
  environment_domain_name = var.environment.project.domain_name
  namespace               = var.namespace
  ses_configuration       = jsondecode(data.aws_ssm_parameter.ses_configuration.value)
  ses_smtp_users          = jsondecode(data.aws_ssm_parameter.ses_smtp_users.value)
  from_email              = "${local.ses_configuration.fromUsername}@${local.environment_domain_name}"
  email_forward_mapping   = local.ses_configuration.emailForwardMapping
  forward_emails = {
    for mapping in local.email_forward_mapping : "${mapping.sourceUsername}@${local.environment_domain_name}" => mapping.destinationEmails
  }
  tags = var.tags
}

provider "aws" {}

# ------------------------------------------------------------------------------
# Module configuration
# ------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

data "aws_route53_zone" "this" {
  name = local.root_domain_name
}

data "aws_ssm_parameter" "ses_configuration" {
  name = var.ssm_parameter_ses_configuration
}

data "aws_ssm_parameter" "ses_smtp_users" {
  name = var.ssm_parameter_ses_smtp_users
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
  name          = "${local.namespace}-receipt-rule"
  rule_set_name = aws_ses_receipt_rule_set.this.rule_set_name
  recipients    = keys(local.forward_emails)
  enabled       = true
  scan_enabled  = true

  s3_action {
    bucket_name = module.inbound_emails_s3_bucket.s3_bucket_id
    position    = 1
  }

  lambda_action {
    function_arn = module.aws_lambda_ses_email_forwarder.lambda_function_arn
    position     = 2
  }

  depends_on = [
    aws_ses_receipt_rule_set.this,
    module.inbound_emails_s3_bucket
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

    resources = [
      "${module.inbound_emails_s3_bucket.s3_bucket_arn}/*",
    ]

    condition {
      test     = "StringEquals"
      values   = [data.aws_caller_identity.current.account_id]
      variable = "aws:Referer"
    }
  }
}

module "inbound_emails_s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "${local.namespace}-inbound-emails"

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

  attach_policy = true
  policy        = data.aws_iam_policy_document.ses_write_to_s3_bucket.json

  tags = local.tags
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
    BUCKET_NAME        = module.inbound_emails_s3_bucket.s3_bucket_id
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
    sid     = "GiveAWSLambdaPermissionToReadEmail"
    effect  = "Allow"
    actions = ["s3:GetObject"]
    resources = [
      "${module.inbound_emails_s3_bucket.s3_bucket_arn}/*",
    ]
  }

  statement {
    sid       = "GiveAWSLambdaPermissionToSendEmail"
    effect    = "Allow"
    actions   = ["ses:SendRawEmail"]
    resources = ["*"]
  }
}

resource "aws_iam_user" "smtp_user" {
  count = length(local.ses_smtp_users)

  name = local.ses_smtp_users[count.index]
  tags = local.tags
}

data "aws_iam_policy_document" "send_mail" {
  statement {
    actions   = ["ses:SendRawEmail"]
    resources = [aws_ses_domain_identity.this.arn]
  }
}

resource "aws_iam_policy" "send_mail" {
  count = length(local.ses_smtp_users)

  name   = "${local.ses_smtp_users[count.index]}-send-mail"
  policy = data.aws_iam_policy_document.send_mail.json
  tags   = local.tags
}

resource "aws_iam_user_policy_attachment" "send_mail" {
  count = length(local.ses_smtp_users)

  policy_arn = aws_iam_policy.send_mail[count.index].arn
  user       = aws_iam_user.smtp_user[count.index].name
}
