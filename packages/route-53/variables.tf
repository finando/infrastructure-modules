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
