aws_region     = "us-east-1"
app_name       = "acrn-react"
domain_name    = "cele.rocks"
hosted_zone_id = "Z06796682YS2JSUKLK80G" # Replace with your zone ID

# Security: External ID for role assumption
terraform_deploy_external_id = "terraform-deploy-acrn"

# Optional: For remote state (recommended for teams)
terraform_state_bucket = "tf-state-acrn-dev"
terraform_lock_table   = "tf-lock-acrn"

# Optional: Enable GitHub Actions OIDC (no secrets!)
enable_github_actions_oidc = true
github_repo                = "nargallegos/acrn-react"
