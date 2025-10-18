# Used for the subdomain part of the URL (e.g., 'acrn'.cele.rocks)
app_name = "acrn"

# The root domain that matches your Route 53 Hosted Zone
domain_name = "cele.rocks"

# The exact name of your service in the App Runner console
apprunner_service_name = "ACRN-React"

hosted_zone_id = "Z06796682YS2JSUKLK80G"

# Security: External ID for role assumption
terraform_deploy_external_id = "terraform-deploy-acrn"

# Optional: For remote state (recommended for teams)
terraform_state_bucket = "tf-state-acrn-dev"
terraform_lock_table   = "tf-lock-acrn"

# Optional: Enable GitHub Actions OIDC (no secrets!)
enable_github_actions_oidc = true
github_repo                = "nargallegos/acrn-react"
