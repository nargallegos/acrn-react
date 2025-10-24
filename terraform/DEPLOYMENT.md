# Deployment Guide - ACRN React to AWS App Runner

This guide provides step-by-step instructions for deploying the ACRN React application to AWS App Runner using Terraform.

## 📋 Prerequisites

- AWS Account
- AWS CLI installed and configured
- Terraform >= 1.0 installed
- Docker (for building and pushing images to ECR)
- Route53 hosted zone for your domain

## 🚀 Initial Setup (One-Time)

### Step 1: Configure Variables

Edit `terraform.tfvars`:

```hcl
aws_region     = "us-east-1"
app_name       = "acrn-react"
domain_name    = "acrn-iac.cele.rocks"
hosted_zone_id = "Z1234567890ABC"  # Your Route53 hosted zone ID

# Optional: Enable GitHub Actions OIDC
enable_github_actions_oidc = false
github_repo                = ""  # Format: "username/repository"

# Optional: Terraform remote state
terraform_state_bucket = ""
terraform_lock_table   = ""
```

### Step 2: Initial Terraform Deployment

**Important:** This first deployment requires AWS admin privileges to create IAM roles.

```bash
cd terraform/

# Initialize Terraform
terraform init

# Review what will be created
terraform plan

# Create all resources including IAM roles
terraform apply
```

After successful deployment, Terraform will output:
- The App Runner service URL
- IAM role ARNs
- Deployment instructions

### Step 3: Save Deployment Role Information

```bash
# Save these for future use
terraform output terraform_deploy_role_arn
terraform output deployment_instructions
```

## 🔄 Subsequent Deployments

After the initial setup, use one of these methods (NO ADMIN PRIVILEGES NEEDED):

### Method 1: Using AWS CLI Profile (Quick & Easy)

1. **Configure AWS CLI profile** (~/.aws/config):

```ini
[profile acrn-deploy]
role_arn = arn:aws:iam::YOUR_ACCOUNT_ID:role/acrn-react-terraform-deploy
external_id = terraform-deploy-acrn
source_profile = default
region = us-east-1
```

2. **Deploy:**

```bash
cd terraform/
AWS_PROFILE=acrn-deploy terraform plan
AWS_PROFILE=acrn-deploy terraform apply
```

### Method 2: Using the Helper Script

```bash
cd terraform/

# Source the script (exports temporary credentials)
source assume-role.sh

# Now run Terraform normally
terraform plan
terraform apply
```

### Method 3: GitHub Actions (CI/CD)

See the example workflow at `examples/github-actions-workflow.yml`

## 📦 Container Image Updates

When you update your application code, you need to:

1. **Build and tag the new image:**

```bash
docker build -t acrn-react:new-tag .
```

2. **Push to ECR:**

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Tag for ECR
docker tag acrn-react:new-tag YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/cele/acrn-react:new-tag

# Push
docker push YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/cele/acrn-react:new-tag
```

3. **Update Terraform:**

Edit `terraform/apprunner.tf`:

```hcl
image_identifier = "YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/cele/acrn-react:new-tag"
```

4. **Deploy:**

```bash
terraform apply
```

## 🔍 Verification

After deployment, verify everything works:

```bash
# Get the App Runner URL
terraform output app_url

# Test the endpoint
curl $(terraform output -raw app_url)

# Check DNS (may take a few minutes to propagate)
dig acrn-iac.cele.rocks

# Visit in browser
open https://acrn-iac.cele.rocks
```

## 🛠️ Common Operations

### View Current Infrastructure

```bash
terraform show
```

### Check State

```bash
terraform state list
```

### View Specific Resource

```bash
terraform state show aws_apprunner_service.acrn_app
```

### Plan Changes Only (No Apply)

```bash
terraform plan
```

### Destroy All Resources

```bash
terraform destroy  # ⚠️ Use with caution!
```

## 📊 Monitoring and Logs

### View App Runner Logs

```bash
# Get service ARN
SERVICE_ARN=$(terraform output -json | jq -r '.app_url.value' | sed 's/https:\/\//arn:aws:apprunner:us-east-1:YOUR_ACCOUNT_ID:service\//')

# View logs
aws apprunner describe-service --service-arn $SERVICE_ARN
```

### CloudWatch Logs

App Runner automatically sends logs to CloudWatch:

```bash
aws logs tail /aws/apprunner/acrn-react --follow
```

## 🐛 Troubleshooting

### Issue: "Error assuming role"

**Solution:** Check your AWS credentials and ensure the external ID matches:

```bash
aws sts get-caller-identity
# Verify the external_id in terraform.tfvars matches "terraform-deploy-acrn"
```

### Issue: "Image pull failed"

**Solution:** Verify the App Runner role has ECR permissions:

```bash
# Check the role exists
aws iam get-role --role-name acrn-react-apprunner-ecr-access

# Check attached policies
aws iam list-attached-role-policies --role-name acrn-react-apprunner-ecr-access
```

### Issue: "Domain validation failed"

**Solution:** Ensure Route53 hosted zone is correctly configured:

```bash
# Verify hosted zone
aws route53 get-hosted-zone --id YOUR_HOSTED_ZONE_ID

# Check records
aws route53 list-resource-record-sets --hosted-zone-id YOUR_HOSTED_ZONE_ID
```

### Issue: Terraform state locked

**Solution:** If using DynamoDB locking and a previous operation failed:

```bash
# Force unlock (use the Lock ID from error message)
terraform force-unlock LOCK_ID
```

## 🔐 Security Checklist

- [ ] No AWS access keys committed to Git
- [ ] IAM roles use least privilege permissions
- [ ] Terraform state is stored securely (encrypted S3 bucket)
- [ ] DynamoDB state locking is enabled
- [ ] External ID is used for role assumption
- [ ] CloudTrail is logging all API calls
- [ ] SSL/TLS enabled (App Runner default)
- [ ] Custom domain uses HTTPS

## 📚 Additional Resources

- [App Runner Documentation](https://docs.aws.amazon.com/apprunner/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [AWS SSO Setup Guide](https://docs.aws.amazon.com/singlesignon/latest/userguide/getting-started.html)

## 🆘 Getting Help

If you encounter issues:

1. Check the troubleshooting section above
2. Review Terraform logs: `terraform plan -debug`
3. Check AWS CloudTrail for API errors
4. Review CloudWatch logs for application errors

## 📝 Next Steps

After successful deployment:

1. [ ] Set up monitoring and alerts
2. [ ] Configure auto-scaling (if needed)
3. [ ] Set up CI/CD pipeline (GitHub Actions)
4. [ ] Configure custom domain SSL certificate
5. [ ] Set up backup and disaster recovery
6. [ ] Document runbooks for common operations

