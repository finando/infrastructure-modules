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

variable "ssm_parameter_ses_configuration" {
  description = "Name of SSM parameter that contains SES configuration (formatted as JSON)"
  type        = string
}

variable "ssm_parameter_ses_smtp_users" {
  description = "Name of SSM parameter that contains SES SMTP users (formatted as JSON)"
  type        = string
}
