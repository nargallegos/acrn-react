# IAM Setup Guide - Modern Best Practices (No Access Keys!)

This guide explains how to set up IAM roles for deploying your App Runner infrastructure using **temporary credentials only** - following AWS security best practices.

## Overview

We've created a secure, least-privilege IAM setup with:

1. **App Runner ECR Access Role** - Allows App Runner to pull container images from ECR
2. **Terraform Deployment Role** - Allows authorized users/systems to deploy infrastructure
3. **GitHub Actions OIDC Role** (Optional) - Enables CI/CD without secrets

## 🚀 Quick Start

### Prerequisites

You need an AWS account with administrator privileges to create the initial IAM roles. After setup, you won't need admin access for deployments.

### Step 1: Initial Terraform Deployment

For the **first deployment only**, you'll need admin privileges to create the IAM roles:

```bash
cd terraform/

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply (this creates all IAM roles)
terraform apply
```

After this runs, you'll see output with the ARNs of created roles and deployment instructions.

### Step 2: Save the Deployment Role ARN

```bash
# Save this ARN - you'll use it for all future deployments
terraform output terraform_deploy_role_arn
```

## 📋 Deployment Methods

### Option 1: Local Development with AssumeRole (Recommended for Developers)

This method uses temporary credentials that expire after 1 hour.

#### Setup AWS CLI Profile

Edit `~/.aws/config`:

```ini
[profile acrn-deploy]
role_arn = arn:aws:iam::YOUR_ACCOUNT_ID:role/acrn-react-terraform-deploy
external_id = terraform-deploy-acrn
source_profile = default
region = us-east-1
```

#### Use the Profile

```bash
# Test it works
aws sts get-caller-identity --profile acrn-deploy

# Deploy with Terraform
cd terraform/
terraform plan --profile acrn-deploy
terraform apply --profile acrn-deploy
```

#### Manual AssumeRole (Alternative)

If you prefer to manually assume the role:

```bash
# Assume the role and get temporary credentials
aws sts assume-role \
  --role-arn arn:aws:iam::YOUR_ACCOUNT_ID:role/acrn-react-terraform-deploy \
  --role-session-name terraform-deploy \
  --external-id terraform-deploy-acrn

# The output contains temporary credentials
# Export them as environment variables:
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."

# Now run Terraform
terraform plan
terraform apply
```

### Option 2: AWS SSO / IAM Identity Center (Best for Organizations)

This is the **most secure option** for human users and recommended for teams.

#### Setup

1. **Enable AWS IAM Identity Center** (formerly AWS SSO)
   - Go to: https://console.aws.amazon.com/singlesignon
   - Click "Enable"

2. **Create a Permission Set**
   - Name: `TerraformDeployer`
   - Create a custom permission set with this policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "arn:aws:iam::YOUR_ACCOUNT_ID:role/acrn-react-terraform-deploy"
    }
  ]
}
```

3. **Assign Users to the Permission Set**
   - Assign your developers to the permission set
   - Select your AWS account

4. **Configure AWS CLI**

```bash
aws configure sso
```

Follow prompts:
- SSO session name: `acrn-sso`
- SSO start URL: Your Identity Center URL
- SSO region: us-east-1
- CLI profile name: `acrn-sso`

#### Usage

```bash
# Login (opens browser)
aws sso login --profile acrn-sso

# Deploy
cd terraform/
terraform plan --profile acrn-sso
terraform apply --profile acrn-sso
```

### Option 3: GitHub Actions with OIDC (Zero Secrets!)

This method uses OpenID Connect - **no AWS credentials stored in GitHub!**

#### Enable GitHub Actions OIDC

Update your `terraform.tfvars`:

```hcl
enable_github_actions_oidc = true
github_repo                = "your-username/your-repo"
```

Apply Terraform:

```bash
terraform apply
```

#### GitHub Actions Workflow

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to AWS App Runner

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  id-token: write   # Required for OIDC
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Configure AWS credentials (OIDC - No Secrets!)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: us-east-1
          role-session-name: GitHubActions

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Terraform Init
        working-directory: terraform
        run: terraform init

      - name: Terraform Plan
        working-directory: terraform
        run: terraform plan

      - name: Terraform Apply
        working-directory: terraform
        run: terraform apply -auto-approve
```

**GitHub Secret to Add:**
- `AWS_ROLE_ARN`: Get from `terraform output github_actions_role_arn`

## 🔒 Security Features

### Least Privilege Principles

1. **Scoped Permissions**: Each role has only the permissions it needs
2. **Resource Constraints**: Actions limited to specific resources (e.g., only `acrn-react` App Runner service)
3. **Conditional Access**: PassRole only works for App Runner service
4. **Time-Limited**: Temporary credentials expire (1 hour max session)
5. **External ID**: Prevents confused deputy attacks

### What's NOT Allowed

The deployment role **cannot**:
- Create or manage EC2 instances
- Access S3 buckets (except Terraform state)
- Manage other App Runner services
- Create arbitrary IAM roles (only `acrn-react-*` pattern)
- Access secrets or parameter store (add if needed)

## 🔄 Updating the Deployment Role

If you need to add permissions:

1. Edit `terraform/iam.tf`
2. Modify the `aws_iam_policy.terraform_deploy` resource
3. Apply changes:

```bash
terraform apply
```

The role updates immediately - no credential rotation needed!

## 📊 Auditing

All role assumptions are logged in CloudTrail:

```bash
# View recent role assumptions
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceName,AttributeValue=acrn-react-terraform-deploy \
  --max-results 10
```

## ❓ Troubleshooting

### "Access Denied" when assuming role

Check:
1. Your base AWS credentials are valid
2. The external ID matches (`terraform-deploy-acrn`)
3. Your user/role is in the same account
4. The trust policy allows your principal

### "Not authorized to perform iam:PassRole"

The deployment role can only pass roles with the pattern `acrn-react-*` to App Runner.

### Session expired

Temporary credentials expire after 1 hour. Re-run:
```bash
aws sts assume-role ...
# or
aws sso login --profile acrn-sso
```

## 🎯 Recommendations

**For Individual Developers:**
- Use Option 1 (AssumeRole with CLI profile)

**For Teams/Organizations:**
- Use Option 2 (AWS SSO/IAM Identity Center)

**For CI/CD Pipelines:**
- Use Option 3 (OIDC - no secrets!)

## 📝 Next Steps

1. ✅ Deploy the Terraform to create IAM roles
2. ✅ Choose your deployment method
3. ✅ Set up your AWS CLI profile or SSO
4. ✅ Test with `terraform plan`
5. ✅ Deploy with `terraform apply`
6. ✅ Revoke any old access keys you may have!

---

**Security Tip:** Never commit AWS credentials to Git. With this setup, you don't need any long-lived credentials at all! 🎉

