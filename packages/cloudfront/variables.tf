variable "common" {
  description = "Common variables"
  type        = object({ project = map(string), tags = map(string) })
}

variable "account" {
  description = "Account variables"
  type        = object({ tags = map(string) })
}

variable "region" {
  description = "Region variables"
  type        = object({ name = string, tags = map(string) })
}

variable "environment" {
  description = "Environment variables"
  type        = object({ name = string, project = map(string), tags = map(string) })
}

variable "namespace" {
  description = "Unique namespace"
  type        = string
}

variable "tags" {
  description = "Tags"
  type        = map(string)
}

variable "cloudfront_distributions" {
  description = "List of Cloudfront distribution definitions"
  type = list(object({
    domain_name = string
    name        = string
    cache_behaviours = list(object({
      path                = optional(string)
      type                = string
      disable_cache       = optional(bool, false)
      rewrite_request_url = optional(bool, false)
      target_origin_id    = string
    }))
    api_gateway_origins = optional(list(object({
      id          = string
      domain_name = string
      origin_path = optional(string)
    })), [])
    s3_origins = optional(list(object({
      id            = string
      domain_name   = string
      s3_bucket_id  = string
      s3_bucket_arn = string
    })), [])
    custom_error_response = optional(list(object({
      error_code         = number
      response_code      = number
      response_page_path = string
    })))
  }))
}
