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
  type        = object({ name = string, tags = map(string) })
}

variable "from_email" {
  description = "Email address to forward emails from"
  type        = string
}

variable "forward_emails" {
  description = "Email forwarding configuration"
  type        = map(list(string))
  default     = {}
}
