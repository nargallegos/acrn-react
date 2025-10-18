# Project Structure

## 📁 Terraform Directory Layout

```
terraform/
├── 🔧 Core Infrastructure Files
│   ├── main.tf              - Terraform & AWS provider configuration
│   ├── iam.tf               - IAM roles & policies (NEW - no access keys!)
│   ├── apprunner.tf         - App Runner service configuration
│   ├── route53.tf           - DNS and custom domain setup
│   ├── variables.tf         - Input variables
│   ├── outputs.tf           - Output values & deployment instructions
│   └── terraform.tfvars     - Your configuration values
│
├── 📚 Documentation
│   ├── GETTING-STARTED.md   - Quick start guide (START HERE!)
│   ├── IAM-SETUP.md         - Detailed IAM configuration guide
│   ├── DEPLOYMENT.md        - Deployment procedures & troubleshooting
│   ├── IAM-REFERENCE.md     - Technical IAM reference
│   └── PROJECT-STRUCTURE.md - This file
│
├── 🛠️ Helper Tools
│   ├── assume-role.sh       - Script to assume deployment role
│   └── Makefile             - Make targets for common operations
│
└── 📋 examples/
    ├── github-actions-workflow.yml  - CI/CD workflow template
    └── sso-permission-set.json      - AWS SSO permission set

```

## 🏗️ Infrastructure Components

### IAM Layer (Security)
```
┌─────────────────────────────────────────────────────────────┐
│                  IAM Roles (No Access Keys!)                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. apprunner-ecr-access                                   │
│     └─> Allows App Runner to pull images from ECR         │
│                                                             │
│  2. terraform-deploy                                       │
│     └─> Allows deployment via assumed role                │
│         ├─ App Runner management                           │
│         ├─ Route53 management                              │
│         ├─ IAM role management (limited)                   │
│         └─ ECR read access                                 │
│                                                             │
│  3. github-actions (optional)                              │
│     └─> CI/CD via OIDC (no secrets!)                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Application Layer
```
┌─────────────────────────────────────────────────────────────┐
│                   App Runner Service                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Service: acrn-react                                       │
│  Source: ECR (cele/acrn-react)                             │
│  Port: 3000                                                │
│  Auto-deploy: Enabled                                      │
│                                                             │
│  ├─ Uses: apprunner-ecr-access role                        │
│  ├─ SSL/TLS: Automatic                                     │
│  └─ Custom Domain: acrn-iac.cele.rocks                     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### DNS Layer
```
┌─────────────────────────────────────────────────────────────┐
│                     Route53 Configuration                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Hosted Zone: cele.rocks                                   │
│    └─ CNAME with Alias: acrn-iac.cele.rocks                │
│       └─> Points to App Runner URL                         │
│                                                             │
│  Custom Domain Association:                                │
│    └─ Links domain to App Runner service                   │
│    └─ Automatic SSL certificate                            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 🔄 Deployment Flow

### First-Time Setup
```
┌─────────────┐
│   Admin     │
│ Credentials │
└──────┬──────┘
       │
       ▼
┌──────────────────┐
│ terraform init   │
│ terraform apply  │ ← Creates ALL IAM roles
└──────┬───────────┘
       │
       ▼
┌────────────────────────────────┐
│  IAM Roles Created             │
│  ✓ apprunner-ecr-access        │
│  ✓ terraform-deploy            │
│  ✓ github-actions (optional)   │
└────────────────────────────────┘
```

### Subsequent Deployments (No Admin Needed!)
```
┌─────────────────┐
│   Developer     │
└────────┬────────┘
         │
         ▼
┌──────────────────────────────┐
│  Assume Deployment Role      │
│  (Temporary Credentials)     │
│                              │
│  Option 1: AWS CLI Profile   │
│  Option 2: AWS SSO           │
│  Option 3: Helper Script     │
└────────┬─────────────────────┘
         │
         ▼
┌──────────────────────────────┐
│  terraform plan/apply        │
│  (Using temporary creds)     │
└────────┬─────────────────────┘
         │
         ▼
┌──────────────────────────────┐
│  Infrastructure Updated      │
│  Credentials auto-expire     │
│  in 1 hour                   │
└──────────────────────────────┘
```

### CI/CD Flow (GitHub Actions)
```
┌─────────────┐
│  git push   │
└──────┬──────┘
       │
       ▼
┌──────────────────────┐
│  GitHub Actions      │
│  Workflow Triggered  │
└──────┬───────────────┘
       │
       ▼
┌────────────────────────────┐
│  OIDC Authentication       │
│  (No secrets in GitHub!)   │
└──────┬─────────────────────┘
       │
       ▼
┌────────────────────────────┐
│  Assume github-actions     │
│  Role (Temporary Creds)    │
└──────┬─────────────────────┘
       │
       ▼
┌────────────────────────────┐
│  terraform apply           │
│  Deploy to Production      │
└────────────────────────────┘
```

## 📖 File Purposes

### Infrastructure Files

| File | Purpose | Edit Frequency |
|------|---------|----------------|
| `main.tf` | Provider config | Rarely |
| `iam.tf` | IAM roles & policies | Occasionally |
| `apprunner.tf` | App Runner service | Per deployment |
| `route53.tf` | DNS configuration | Rarely |
| `variables.tf` | Variable definitions | Occasionally |
| `outputs.tf` | Output values | Occasionally |
| `terraform.tfvars` | Your settings | Initially, then rarely |

### Documentation Files

| File | Audience | When to Read |
|------|----------|--------------|
| `GETTING-STARTED.md` | First-time users | Before first deployment |
| `IAM-SETUP.md` | All users | Setting up auth method |
| `DEPLOYMENT.md` | Operators | Regular deployments |
| `IAM-REFERENCE.md` | Admins/Security | Understanding IAM setup |
| `PROJECT-STRUCTURE.md` | All users | Understanding layout |

### Helper Files

| File | Purpose | How to Use |
|------|---------|------------|
| `assume-role.sh` | Get temp credentials | `source assume-role.sh` |
| `Makefile` | Common operations | `make plan`, `make apply` |
| `examples/*.yml` | Templates | Copy and customize |
| `examples/*.json` | AWS configs | Import into AWS |

## 🎯 Quick Reference

### Most Common Commands

```bash
# Initial setup
cd terraform/
terraform init
terraform apply

# Regular deployment (with AWS CLI profile)
AWS_PROFILE=acrn-deploy terraform plan
AWS_PROFILE=acrn-deploy terraform apply

# Using helper script
source assume-role.sh
terraform plan
terraform apply

# Update app (new Docker image)
# 1. Edit apprunner.tf (update image tag)
# 2. Deploy
terraform apply
```

### Most Important Files to Review

1. **Start:** `GETTING-STARTED.md`
2. **Auth:** `IAM-SETUP.md`
3. **Deploy:** `DEPLOYMENT.md`
4. **Config:** `terraform.tfvars`
5. **Reference:** `IAM-REFERENCE.md`

## 🔐 Security Architecture

```
┌────────────────────────────────────────────────────────────┐
│                    Security Layers                         │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  Layer 1: Authentication (No Access Keys!)                │
│  ├─ AWS CLI AssumeRole                                    │
│  ├─ AWS SSO/IAM Identity Center                           │
│  └─ OIDC (GitHub Actions)                                 │
│                                                            │
│  Layer 2: Authorization (Least Privilege)                 │
│  ├─ Scoped to specific resources                          │
│  ├─ Conditional policies                                  │
│  └─ External ID for AssumeRole                            │
│                                                            │
│  Layer 3: Auditing (Full Traceability)                    │
│  ├─ CloudTrail logs all actions                           │
│  ├─ Session names identify actors                         │
│  └─ Time-bounded sessions                                 │
│                                                            │
│  Layer 4: Encryption                                      │
│  ├─ SSL/TLS (App Runner default)                          │
│  ├─ Encrypted Terraform state                             │
│  └─ Secure credential transmission                        │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

## 📊 Comparison: Before vs After

| Aspect | Before (Old Way) | After (Modern Way) |
|--------|------------------|-------------------|
| **Credentials** | Long-lived access keys | Temporary (1 hour) |
| **Security Risk** | High (can be leaked) | Low (auto-expire) |
| **Audit Trail** | Limited | Full (CloudTrail) |
| **CI/CD Secrets** | Stored in GitHub | None (OIDC) |
| **Rotation** | Manual | Automatic |
| **Revocation** | Delete keys | Update role trust |
| **Compliance** | Difficult | Easy |

## 🎓 Learning Path

1. **Beginner**
   - Read `GETTING-STARTED.md`
   - Deploy using AWS CLI profile
   - Understand basic IAM concepts

2. **Intermediate**
   - Set up AWS SSO
   - Understand role assumption
   - Customize IAM policies

3. **Advanced**
   - Implement GitHub Actions OIDC
   - Set up remote state backend
   - Create multiple environments
   - Implement advanced monitoring

## 📞 Quick Help

| Problem | See |
|---------|-----|
| Can't assume role | `IAM-SETUP.md` |
| Deployment fails | `DEPLOYMENT.md` → Troubleshooting |
| IAM questions | `IAM-REFERENCE.md` |
| First time user | `GETTING-STARTED.md` |
| CI/CD setup | `examples/github-actions-workflow.yml` |

---

**Navigation:**
- 🏠 [Main README](../README.md)
- 🚀 [Getting Started](GETTING-STARTED.md)
- 🔐 [IAM Setup](IAM-SETUP.md)
- 📦 [Deployment Guide](DEPLOYMENT.md)
- 📖 [IAM Reference](IAM-REFERENCE.md)

**Last Updated:** October 2025

