# Getting Started - Secure AWS Deployment

Welcome! This guide will walk you through deploying your ACRN React app to AWS App Runner using modern IAM best practices (no access keys!).

## 📋 What You'll Set Up

By following this guide, you'll create:

✅ AWS App Runner service hosting your React application  
✅ Custom domain with automatic SSL/TLS  
✅ Route53 DNS records  
✅ Secure IAM roles (no long-lived credentials!)  
✅ Optional: GitHub Actions CI/CD (no secrets!)  

## ⏱️ Time Required

- **First-time setup:** ~20 minutes
- **Subsequent deployments:** ~2 minutes

## 📦 Prerequisites

Before you begin, ensure you have:

- [ ] AWS Account with admin access (only for initial setup)
- [ ] AWS CLI installed and configured ([Install Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html))
- [ ] Terraform >= 1.0 installed ([Install Guide](https://developer.hashicorp.com/terraform/downloads))
- [ ] Route53 hosted zone for your domain
- [ ] Container image in ECR (or Docker installed to build one)

### Verify Prerequisites

```bash
# Check AWS CLI
aws --version
# Should show: aws-cli/2.x.x or higher

# Check Terraform
terraform --version
# Should show: Terraform v1.x.x or higher

# Test AWS access
aws sts get-caller-identity
# Should show your AWS account info
```

## 🚀 Step-by-Step Setup

### Step 1: Configure Your Variables

1. **Navigate to the terraform directory:**
   ```bash
   cd terraform/
   ```

2. **Get your Route53 hosted zone ID:**
   ```bash
   aws route53 list-hosted-zones
   # Copy the zone ID for your domain
   ```

3. **Edit terraform.tfvars:**
   ```bash
   # Create or edit terraform.tfvars
   cat > terraform.tfvars << 'EOF'
   aws_region     = "us-east-1"
   app_name       = "acrn-react"
   domain_name    = "acrn-iac.cele.rocks"
   hosted_zone_id = "Z1234567890ABC"  # Replace with your zone ID
   
   # Security: External ID for role assumption
   terraform_deploy_external_id = "terraform-deploy-acrn"
   
   # Optional: For remote state (recommended for teams)
   terraform_state_bucket = ""
   terraform_lock_table   = ""
   
   # Optional: Enable GitHub Actions OIDC (no secrets!)
   enable_github_actions_oidc = false
   github_repo                = ""  # e.g., "yourusername/acrn-react"
   EOF
   ```

### Step 2: Container Image Setup

You need a container image in ECR. Choose one option:

#### Option A: Build and Push New Image

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Create ECR repository (if it doesn't exist)
aws ecr create-repository --repository-name cele/acrn-react --region us-east-1

# Build the image
cd ..  # Back to project root
docker build -t acrn-react:latest .

# Tag for ECR
docker tag acrn-react:latest YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/cele/acrn-react:latest

# Push to ECR
docker push YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/cele/acrn-react:latest

# Back to terraform directory
cd terraform/
```

#### Option B: Use Existing Image

If you already have an image in ECR, just update the image identifier in `apprunner.tf`.

### Step 3: Initial Terraform Deployment

**⚠️ Important:** This first deployment requires admin privileges to create IAM roles.

```bash
# Initialize Terraform
terraform init

# Review what will be created
terraform plan

# Review the output carefully - you should see:
# - 2-3 IAM roles
# - 1 App Runner service
# - 2 Route53 resources
# - 1-2 IAM policies

# Apply the configuration
terraform apply

# Type 'yes' when prompted
```

This will take 3-5 minutes. ☕

### Step 4: Save Deployment Credentials

After successful deployment:

```bash
# Save the deployment role ARN (you'll need this!)
terraform output terraform_deploy_role_arn

# View deployment instructions
terraform output deployment_instructions

# Test the deployed app
terraform output app_url
curl $(terraform output -raw app_url)
```

**🔴 Critical:** Save the `terraform_deploy_role_arn` - you'll use this for all future deployments!

### Step 5: Set Up Your Deployment Method

Choose the method that works best for you:

#### 🎯 Recommended for Developers: AWS CLI Profile

Edit `~/.aws/config`:

```ini
[profile acrn-deploy]
role_arn = arn:aws:iam::YOUR_ACCOUNT_ID:role/acrn-react-terraform-deploy
external_id = terraform-deploy-acrn
source_profile = default
region = us-east-1
```

**Test it:**
```bash
aws sts get-caller-identity --profile acrn-deploy
```

**Use it:**
```bash
AWS_PROFILE=acrn-deploy terraform plan
AWS_PROFILE=acrn-deploy terraform apply
```

#### 🎯 Recommended for Teams: AWS SSO

See detailed setup in [IAM-SETUP.md](IAM-SETUP.md#option-2-aws-sso--iam-identity-center-best-for-organizations)

#### 🎯 Recommended for CI/CD: GitHub Actions OIDC

See detailed setup in [IAM-SETUP.md](IAM-SETUP.md#option-3-github-actions-with-oidc-zero-secrets)

## ✅ Verification Checklist

After deployment, verify everything works:

- [ ] App Runner service is running:
  ```bash
  aws apprunner list-services --region us-east-1
  ```

- [ ] DNS record exists:
  ```bash
  dig acrn-iac.cele.rocks
  ```

- [ ] App is accessible:
  ```bash
  curl https://acrn-iac.cele.rocks
  ```

- [ ] IAM roles created:
  ```bash
  aws iam get-role --role-name acrn-react-terraform-deploy
  aws iam get-role --role-name acrn-react-apprunner-ecr-access
  ```

- [ ] Can assume deployment role:
  ```bash
  aws sts assume-role \
    --role-arn arn:aws:iam::YOUR_ACCOUNT_ID:role/acrn-react-terraform-deploy \
    --role-session-name test \
    --external-id terraform-deploy-acrn
  ```

## 🔄 Making Changes

### Updating Application Code

```bash
# 1. Make code changes
# 2. Build new Docker image
docker build -t acrn-react:v2 .

# 3. Push to ECR with new tag
docker tag acrn-react:v2 YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/cele/acrn-react:v2
docker push YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/cele/acrn-react:v2

# 4. Update apprunner.tf with new image tag
# 5. Deploy
cd terraform/
AWS_PROFILE=acrn-deploy terraform apply
```

### Updating Infrastructure

```bash
# 1. Edit Terraform files
# 2. Review changes
AWS_PROFILE=acrn-deploy terraform plan

# 3. Apply changes
AWS_PROFILE=acrn-deploy terraform apply
```

## 🔐 Security Best Practices

✅ **What We Did:**
- Created IAM roles with least privilege
- No long-lived access keys
- External ID for role assumption security
- Scoped permissions to specific resources
- 1-hour session limits

❌ **What NOT to Do:**
- Don't create IAM users with access keys
- Don't store credentials in code
- Don't give broad permissions
- Don't skip the external ID
- Don't share credentials

## 📚 Next Steps

Now that you're set up, explore these topics:

1. **[IAM-SETUP.md](IAM-SETUP.md)** - Detailed IAM configuration
2. **[DEPLOYMENT.md](DEPLOYMENT.md)** - Deployment procedures and troubleshooting
3. **[IAM-REFERENCE.md](IAM-REFERENCE.md)** - IAM resource reference
4. **[examples/github-actions-workflow.yml](examples/github-actions-workflow.yml)** - CI/CD setup

### Optional Enhancements

- [ ] Set up CloudWatch alerts
- [ ] Configure auto-scaling
- [ ] Set up staging environment
- [ ] Add monitoring dashboard
- [ ] Configure backup/disaster recovery
- [ ] Set up GitHub Actions CI/CD
- [ ] Enable CloudTrail logging

## 🐛 Troubleshooting

### Common Issues

**"Error assuming role"**
- Verify external ID matches
- Check your AWS credentials
- Ensure you're in the correct account

**"Image not found"**
- Verify ECR repository exists
- Check image tag in apprunner.tf
- Ensure App Runner role has ECR permissions

**"Domain validation failed"**
- Verify Route53 hosted zone
- Check hosted_zone_id in terraform.tfvars
- DNS propagation can take 5-10 minutes

**"Terraform state locked"**
- Wait for other operations to complete
- Use `terraform force-unlock LOCK_ID` if needed

For detailed troubleshooting, see [DEPLOYMENT.md](DEPLOYMENT.md#-troubleshooting)

## 🆘 Getting Help

If you're stuck:

1. Check the [DEPLOYMENT.md](DEPLOYMENT.md) troubleshooting section
2. Review CloudTrail for API errors
3. Check CloudWatch logs for application errors
4. Verify AWS service quotas
5. Review Terraform state: `terraform show`

## 🎉 Success!

If you've completed all steps, congratulations! You now have:

✅ A secure, production-ready deployment pipeline  
✅ No long-lived AWS credentials  
✅ Infrastructure as code with Terraform  
✅ Custom domain with SSL  
✅ Least-privilege IAM setup  

**Ready to deploy?**

```bash
AWS_PROFILE=acrn-deploy terraform apply
```

---

**Remember:** You never need to use AWS access keys again! All deployments use temporary credentials through IAM roles. 🎉

**Last Updated:** October 2025  
**Terraform Version:** >= 1.0  
**AWS Provider:** ~> 5.0

