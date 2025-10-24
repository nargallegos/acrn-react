output "app_url" {
  description = "The URL of the App Runner application."
  value       = aws_apprunner_service.acrn_app.service_url
}

# IAM Role Outputs
output "terraform_deploy_role_arn" {
  description = "ARN of the Terraform deployment role (assume this role to deploy)"
  value       = aws_iam_role.terraform_deploy.arn
}

output "apprunner_ecr_access_role_arn" {
  description = "ARN of the App Runner ECR access role"
  value       = aws_iam_role.apprunner_ecr_access.arn
}

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions role (if enabled)"
  value       = var.enable_github_actions_oidc ? aws_iam_role.github_actions[0].arn : null
}

# Deployment Instructions
output "deployment_instructions" {
  description = "Instructions for deploying using the created IAM roles"
  sensitive   = true
  value       = <<-EOT
    
    =================================================================
    DEPLOYMENT INSTRUCTIONS - Using IAM Roles (No Access Keys!)
    =================================================================
    
    Option 1: Local Development (Assume Role)
    ------------------------------------------
    1. Configure AWS CLI to assume the deployment role:
       
       aws configure set role_arn ${aws_iam_role.terraform_deploy.arn}
       aws configure set external_id ${var.terraform_deploy_external_id}
       aws configure set source_profile default
    
    2. Or use this command to assume the role:
       
       aws sts assume-role \
         --role-arn ${aws_iam_role.terraform_deploy.arn} \
         --role-session-name terraform-deploy \
         --external-id ${var.terraform_deploy_external_id}
    
    3. Export the temporary credentials from the output
    
    Option 2: AWS SSO/IAM Identity Center (Recommended)
    ----------------------------------------------------
    1. Set up AWS SSO: https://console.aws.amazon.com/singlesignon
    2. Create a permission set that allows AssumeRole on:
       ${aws_iam_role.terraform_deploy.arn}
    3. Use: aws sso login --profile your-sso-profile
    
    ${var.enable_github_actions_oidc ? "Option 3: GitHub Actions (OIDC - No Secrets!)\n    --------------------------------------------\n    Add this to your GitHub Actions workflow:\n    \n    permissions:\n      id-token: write\n      contents: read\n    \n    steps:\n      - uses: aws-actions/configure-aws-credentials@v4\n        with:\n          role-to-assume: ${aws_iam_role.github_actions[0].arn}\n          aws-region: ${var.aws_region}\n    \n    See: terraform/examples/github-actions-workflow.yml" : ""}
    
    =================================================================
  EOT
}
