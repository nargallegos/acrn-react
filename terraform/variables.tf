variable "aws_region" {
  description = "The AWS region to deploy the resources to."
  type        = string
  default     = "us-east-1"
}

variable "app_name" {
  description = "The name of the application."
  type        = string
  default     = "acrn-react"
}

variable "domain_name" {
  description = "The domain name for the application."
  type        = string
  default     = "acrn-iac.cele.rocks"
}

variable "hosted_zone_id" {
  description = "The ID of the hosted zone for the domain."
  type        = string
}
