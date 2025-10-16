# IAM Resources Quick Reference

## Overview of Created IAM Resources

This Terraform configuration creates the following IAM resources with least-privilege permissions:

## 1️⃣ App Runner ECR Access Role

**Resource:** `aws_iam_role.apprunner_ecr_access`  
**Name:** `acrn-react-apprunner-ecr-access`  
**Purpose:** Allows App Runner service to pull container images from Amazon ECR

### Trust Policy
```json
{
  "Principal": {
    "Service": "build.apprunner.amazonaws.com"
  }
}
```

### Permissions
- AWS Managed Policy: `AWSAppRunnerServicePolicyForECRAccess`
  - `ecr:GetAuthorizationToken`
  - `ecr:BatchCheckLayerAvailability`
  - `ecr:GetDownloadUrlForLayer`
  - `ecr:BatchGetImage`

### Used By
- `aws_apprunner_service.acrn_app` (via `authentication_configuration`)

---

## 2️⃣ Terraform Deployment Role

**Resource:** `aws_iam_role.terraform_deploy`  
**Name:** `acrn-react-terraform-deploy`  
**Purpose:** Allows authorized users/systems to deploy infrastructure via Terraform

### Trust Policy
```json
{
  "Principal": {
    "AWS": "arn:aws:iam::ACCOUNT_ID:root"
  },
  "Condition": {
    "StringEquals": {
      "sts:ExternalId": "terraform-deploy-acrn"
    }
  }
}
```

### Permissions (Custom Policy)

#### App Runner Management
- Limited to service name: `acrn-react`
- Actions:
  - `apprunner:CreateService`
  - `apprunner:UpdateService`
  - `apprunner:DeleteService`
  - `apprunner:DescribeService`
  - `apprunner:AssociateCustomDomain`
  - `apprunner:DisassociateCustomDomain`

#### Route53 Management
- Read access: All hosted zones
- Write access: Only specified hosted zone ID
- Actions:
  - `route53:ChangeResourceRecordSets`
  - `route53:ListResourceRecordSets`

#### IAM Role Management
- Limited to roles matching pattern: `acrn-react-*`
- Actions:
  - `iam:CreateRole`
  - `iam:DeleteRole`
  - `iam:AttachRolePolicy`
  - `iam:PassRole` (only to apprunner.amazonaws.com)

#### ECR Read Access
- Actions:
  - `ecr:DescribeRepositories`
  - `ecr:DescribeImages`
  - `ecr:GetAuthorizationToken`

#### Terraform State Access (Optional)
- S3 bucket access for state files
- DynamoDB table access for state locking

### Session Duration
- Maximum: 3600 seconds (1 hour)

### Used By
- Local developers (via `aws sts assume-role`)
- CI/CD systems (via `aws sts assume-role`)
- AWS SSO users (via permission sets)

---

## 3️⃣ GitHub Actions OIDC Role (Optional)

**Resource:** `aws_iam_role.github_actions`  
**Name:** `acrn-react-github-actions`  
**Purpose:** Allows GitHub Actions workflows to deploy without storing AWS credentials

### Trust Policy
```json
{
  "Principal": {
    "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
  },
  "Condition": {
    "StringEquals": {
      "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
    },
    "StringLike": {
      "token.actions.githubusercontent.com:sub": "repo:OWNER/REPO:*"
    }
  }
}
```

### Permissions
- Same as Terraform Deployment Role (via policy attachment)

### Used By
- GitHub Actions workflows (via OIDC authentication)

### Prerequisites
- `enable_github_actions_oidc = true` in terraform.tfvars
- GitHub repository specified in `github_repo` variable
- OIDC provider created: `aws_iam_openid_connect_provider.github_actions`

---

## 🔐 Security Features

### Least Privilege Implementation

1. **Scoped Resources**
   - App Runner: Limited to `acrn-react` service
   - IAM Roles: Limited to `acrn-react-*` pattern
   - Route53: Limited to specified hosted zone

2. **Conditional Access**
   - PassRole: Only allowed for App Runner service
   - External ID: Required for role assumption (prevents confused deputy)
   - OIDC: Limited to specific GitHub repository

3. **Time Limits**
   - Maximum session: 1 hour
   - Automatic credential expiration
   - No long-lived access keys

4. **Audit Trail**
   - All role assumptions logged in CloudTrail
   - API calls tagged with session name
   - Traceable to specific users/systems

### What These Roles CANNOT Do

❌ Create EC2 instances  
❌ Access other AWS services (RDS, Lambda, etc.)  
❌ Modify other App Runner services  
❌ Create arbitrary IAM users or roles  
❌ Access S3 buckets (except Terraform state)  
❌ Modify security groups or VPCs  
❌ Delete or modify other Route53 zones  
❌ Access Secrets Manager or Parameter Store  

---

## 📊 Resource Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     AWS Account                             │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  App Runner Service: acrn-react                     │   │
│  │  ┌──────────────────────────────────────────────┐   │   │
│  │  │ Uses:                                        │   │   │
│  │  │ aws_iam_role.apprunner_ecr_access           │   │   │
│  │  │ (pulls images from ECR)                      │   │   │
│  │  └──────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Deployment Methods                                 │   │
│  │                                                     │   │
│  │  ┌────────────┐  ┌──────────┐  ┌──────────────┐   │   │
│  │  │ Developer  │  │   AWS    │  │   GitHub     │   │   │
│  │  │  (local)   │  │   SSO    │  │   Actions    │   │   │
│  │  └─────┬──────┘  └────┬─────┘  └──────┬───────┘   │   │
│  │        │              │                │           │   │
│  │        └──────────────┼────────────────┘           │   │
│  │                       │                            │   │
│  │                       ▼                            │   │
│  │    ┌────────────────────────────────────────┐     │   │
│  │    │ aws_iam_role.terraform_deploy         │     │   │
│  │    │ (deploys infrastructure)              │     │   │
│  │    └────────────────────────────────────────┘     │   │
│  │                       │                            │   │
│  │                       ▼                            │   │
│  │    ┌────────────────────────────────────────┐     │   │
│  │    │ Terraform Resources                    │     │   │
│  │    │ - App Runner                           │     │   │
│  │    │ - Route53                              │     │   │
│  │    │ - IAM Roles                            │     │   │
│  │    └────────────────────────────────────────┘     │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔍 Verification Commands

### Check Role Exists
```bash
aws iam get-role --role-name acrn-react-terraform-deploy
```

### List Attached Policies
```bash
aws iam list-attached-role-policies --role-name acrn-react-terraform-deploy
```

### Get Policy Document
```bash
aws iam get-role-policy --role-name acrn-react-terraform-deploy --policy-name acrn-react-terraform-deploy-policy
```

### Test Role Assumption
```bash
aws sts assume-role \
  --role-arn arn:aws:iam::ACCOUNT_ID:role/acrn-react-terraform-deploy \
  --role-session-name test \
  --external-id terraform-deploy-acrn
```

### View Role Assumption History (CloudTrail)
```bash
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceName,AttributeValue=acrn-react-terraform-deploy \
  --max-results 10
```

---

## 🔄 Updating Permissions

If you need to add or modify permissions:

1. **Edit the policy** in `iam.tf`:
   ```hcl
   resource "aws_iam_policy" "terraform_deploy" {
     # Modify the policy document
   }
   ```

2. **Apply changes**:
   ```bash
   terraform apply
   ```

3. **No credential rotation needed** - changes take effect immediately!

---

## 📋 Compliance & Auditing

### CloudTrail Events to Monitor

- `AssumeRole` - Who is assuming the deployment role
- `CreateService` - App Runner service creation
- `UpdateService` - Service updates
- `PassRole` - When roles are passed to services
- `ChangeResourceRecordSets` - DNS changes

### Example CloudTrail Query

```bash
# Find all role assumptions in the last 7 days
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=AssumeRole \
  --start-time $(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%S) \
  --query 'Events[?contains(CloudTrailEvent, `acrn-react-terraform-deploy`)]'
```

---

## 🆘 Emergency Access

If the deployment role is accidentally deleted or misconfigured:

1. **Use your admin credentials** to recreate it
2. **Run terraform apply** to restore all IAM resources
3. **Verify** with: `terraform plan` (should show no changes)

### Break-Glass Procedure

```bash
# 1. Switch to admin credentials
export AWS_PROFILE=admin

# 2. Restore IAM resources
cd terraform/
terraform apply -target=aws_iam_role.terraform_deploy

# 3. Verify
terraform plan
```

---

## 📚 Related Documentation

- [IAM-SETUP.md](./IAM-SETUP.md) - Detailed setup guide
- [DEPLOYMENT.md](./DEPLOYMENT.md) - Deployment procedures
- [examples/github-actions-workflow.yml](./examples/github-actions-workflow.yml) - CI/CD example

---

**Last Updated:** October 2025  
**Terraform Version:** >= 1.0  
**AWS Provider Version:** ~> 5.0

