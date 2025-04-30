variable "health_check_id" {
  description = "Route53 Health Check ID for the primary environment"
  type        = string
}

variable "snsEmail" {
  description = "Email address for SNS alarm subscription"
  type = string
}