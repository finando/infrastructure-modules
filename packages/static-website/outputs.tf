
output "static_www_website_s3_bucket_id" {
  description = "The name of the S3 bucket"
  value       = { for website in local.static_websites : website.name => module.s3_bucket_static_www_website[website.name].s3_bucket_id }
}

output "static_www_website_s3_bucket_region" {
  description = "The AWS region the S3 bucket resides in"
  value       = { for website in local.static_websites : website.name => module.s3_bucket_static_www_website[website.name].s3_bucket_region }
}

output "static_www_website_s3_bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = { for website in local.static_websites : website.name => module.s3_bucket_static_www_website[website.name].s3_bucket_arn }
}

output "static_www_website_s3_bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = { for website in local.static_websites : website.name => module.s3_bucket_static_www_website[website.name].s3_bucket_bucket_domain_name }
}

output "static_www_website_s3_bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket"
  value       = { for website in local.static_websites : website.name => module.s3_bucket_static_www_website[website.name].s3_bucket_bucket_regional_domain_name }
}

output "static_www_website_s3_bucket_hosted_zone_id" {
  description = "Hosted zone ID of the S3 bucket"
  value       = { for website in local.static_websites : website.name => module.s3_bucket_static_www_website[website.name].s3_bucket_hosted_zone_id }
}

output "static_www_website_cloudfront_distribution_id" {
  description = "The identifier for the distribution"
  value       = { for website in local.static_websites : website.name => module.cloudfront_static_www_website[website.name].cloudfront_distribution_id }
}

output "static_www_website_cloudfront_distribution_arn" {
  description = "The ARN for the distribution"
  value       = { for website in local.static_websites : website.name => module.cloudfront_static_www_website[website.name].cloudfront_distribution_arn }
}

output "static_www_website_cloudfront_distribution_domain_name" {
  description = "The domain name corresponding to the distribution"
  value       = { for website in local.static_websites : website.name => module.cloudfront_static_www_website[website.name].cloudfront_distribution_domain_name }
}

output "static_www_website_cloudfront_distribution_hosted_zone_id" {
  description = "The CloudFront Route 53 zone ID that can be used to route an Alias Resource Record Set to"
  value       = { for website in local.static_websites : website.name => module.cloudfront_static_www_website[website.name].cloudfront_distribution_hosted_zone_id }
}

output "static_www_website_cloudfront_distribution_record_name" {
  description = "The name of the record"
  value       = { for website in local.static_websites : website.name => aws_route53_record.static_www_website_cloudfront_distribution_route53_record[website.name].name }
}

output "static_www_website_cloudfront_distribution_record_fqdn" {
  description = "Fully qualified domain name"
  value       = { for website in local.static_websites : website.name => aws_route53_record.static_www_website_cloudfront_distribution_route53_record[website.name].fqdn }
}

output "static_www_website_acm_certificate_arn" {
  description = "The ARN of the certificate"
  value       = { for website in local.static_websites : website.name => module.acm[website.name].acm_certificate_arn }
}
