
output "s3_bucket_id" {
  description = "The name of the S3 bucket"
  value       = { for website in local.s3_buckets : website.name => module.s3_bucket[website.name].s3_bucket_id }
}

output "s3_bucket_region" {
  description = "The AWS region the S3 bucket resides in"
  value       = { for website in local.s3_buckets : website.name => module.s3_bucket[website.name].s3_bucket_region }
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = { for website in local.s3_buckets : website.name => module.s3_bucket[website.name].s3_bucket_arn }
}

output "s3_bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = { for website in local.s3_buckets : website.name => module.s3_bucket[website.name].s3_bucket_bucket_domain_name }
}

output "s3_bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket"
  value       = { for website in local.s3_buckets : website.name => module.s3_bucket[website.name].s3_bucket_bucket_regional_domain_name }
}

output "s3_bucket_hosted_zone_id" {
  description = "Hosted zone ID of the S3 bucket"
  value       = { for website in local.s3_buckets : website.name => module.s3_bucket[website.name].s3_bucket_hosted_zone_id }
}
