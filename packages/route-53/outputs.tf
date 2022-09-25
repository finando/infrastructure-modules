output "route53_zone_arn" {
  description = "The Amazon Resource Name (ARN) of the Hosted Zone"
  value       = aws_route53_zone.this.arn
}

output "route53_zone_id" {
  description = "The Hosted Zone ID. This can be referenced by zone records"
  value       = aws_route53_zone.this.zone_id
}

output "route53_zone_name_servers" {
  description = "A list of name servers in associated (or default) delegation set"
  value       = aws_route53_zone.this.name_servers
}
