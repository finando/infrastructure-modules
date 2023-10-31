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

variable "github_pages_txt_record_prefix" {
  description = "TXT DNS record prefix for GitHub Pages"
  type        = string
}

variable "github_pages_txt_record_value" {
  description = "TXT DNS record value for GitHub Pages"
  type        = string
}

variable "dns_records" {
  description = "A map of DNS record definitions"
  type = map(object({
    prefix  = string
    type    = string
    ttl     = string
    records = list(string)
  }))
  default   = {}
  sensitive = true
}
