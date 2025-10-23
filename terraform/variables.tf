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
  description = "The custom domain name to use for the App Runner service"
  type        = string
}

variable "apprunner_service_name" {
  description = "The name of the App Runner service instance"
  type        = string
}

variable "hosted_zone_id" {
  description = "The Route56 hosted zone ID for the custom domain"
  type        = string
}

# IAM Configuration Variables
variable "terraform_deploy_external_id" {
  description = "External ID for assuming the Terraform deployment role (for security)"
  type        = string
  default     = "terraform-deploy-acrn"
  sensitive   = true
}

variable "terraform_state_bucket" {
  description = "S3 bucket for Terraform state (if using remote backend)"
  type        = string
  default     = ""
}

variable "terraform_lock_table" {
  description = "DynamoDB table for Terraform state locking (if using remote backend)"
  type        = string
  default     = ""
}

# GitHub Actions OIDC Configuration (Optional)
variable "enable_github_actions_oidc" {
  description = "Enable GitHub Actions OIDC provider and role"
  type        = bool
  default     = false
}

variable "github_repo" {
  description = "GitHub repository in format 'owner/repo' (required if enable_github_actions_oidc is true)"
  type        = string
  default     = ""
}

variable "root_domain_name" {
  description = "Root domain name"
  type        = string
  default     = ""
}
