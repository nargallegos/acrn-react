# ============================================================================
# IAM Configuration for App Runner Deployment
# Following AWS Best Practices - No Long-Lived Access Keys
# ============================================================================

# ----------------------------------------------------------------------------
# 1. App Runner Service Role - Allows App Runner to pull from ECR
# ----------------------------------------------------------------------------
resource "aws_iam_role" "apprunner_ecr_access" {
  name = "${var.app_name}-apprunner-ecr-access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "build.apprunner.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "AppRunner ECR Access Role"
    Application = var.app_name
    ManagedBy   = "Terraform"
  }
}

# Attach AWS managed policy for ECR access
resource "aws_iam_role_policy_attachment" "apprunner_ecr_policy" {
  role       = aws_iam_role.apprunner_ecr_access.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

# ----------------------------------------------------------------------------
# 2. Terraform Deployment Role - Assumed by administrators or CI/CD
# ----------------------------------------------------------------------------
resource "aws_iam_role" "terraform_deploy" {
  name        = "${var.app_name}-terraform-deploy"
  description = "Role for deploying ${var.app_name} infrastructure via Terraform"

  # This role can be assumed by:
  # - IAM users in the account (for local development)
  # - Other roles (for cross-account deployments)
  # - External identity providers via OIDC (for CI/CD)
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowIAMUsersToAssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.terraform_deploy_external_id
          }
        }
      }
    ]
  })

  # Session duration for temporary credentials
  max_session_duration = 3600 # 1 hour

  tags = {
    Name        = "Terraform Deployment Role"
    Application = var.app_name
    ManagedBy   = "Terraform"
  }
}

# Custom policy for Terraform deployment with least privilege
resource "aws_iam_policy" "terraform_deploy" {
  name        = "${var.app_name}-terraform-deploy-policy"
  description = "Least privilege policy for Terraform to deploy ${var.app_name} to App Runner"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AppRunnerManagement"
        Effect = "Allow"
        Action = [
          "apprunner:CreateService",
          "apprunner:UpdateService",
          "apprunner:DeleteService",
          "apprunner:DescribeService",
          "apprunner:ListServices",
          "apprunner:TagResource",
          "apprunner:UntagResource",
          "apprunner:ListTagsForResource",
          "apprunner:AssociateCustomDomain",
          "apprunner:DisassociateCustomDomain",
          "apprunner:DescribeCustomDomains"
        ]
        Resource = [
          "arn:aws:apprunner:${var.aws_region}:${data.aws_caller_identity.current.account_id}:service/${var.app_name}",
          "arn:aws:apprunner:${var.aws_region}:${data.aws_caller_identity.current.account_id}:service/${var.app_name}/*"
        ]
      },
      {
        Sid    = "Route53ReadAccess"
        Effect = "Allow"
        Action = [
          "route53:GetHostedZone",
          "route53:ListHostedZones",
          "route53:ListHostedZonesByName",
          "route53:GetChange"
        ]
        Resource = "*"
      },
      {
        Sid    = "Route53RecordManagement"
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets"
        ]
        Resource = "arn:aws:route53:::hostedzone/${var.hosted_zone_id}"
      },
      {
        Sid    = "IAMRoleManagement"
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:GetRole",
          "iam:DeleteRole",
          "iam:UpdateRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:GetRolePolicy",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:ListRoleTags"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.app_name}-*"
      },
      {
        Sid    = "PassRoleToAppRunner"
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.app_name}-apprunner-*"
        ]
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "apprunner.amazonaws.com"
          }
        }
      },
      {
        Sid    = "ECRReadAccess"
        Effect = "Allow"
        Action = [
          "ecr:DescribeRepositories",
          "ecr:DescribeImages",
          "ecr:ListImages",
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Sid    = "TerraformStateAccess"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.terraform_state_bucket}",
          "arn:aws:s3:::${var.terraform_state_bucket}/*"
        ]
      },
      {
        Sid    = "TerraformStateLocking"
        Effect = "Allow"
        Action = [
          "dynamodb:DescribeTable",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.terraform_lock_table}"
      }
    ]
  })

  tags = {
    Name        = "Terraform Deployment Policy"
    Application = var.app_name
    ManagedBy   = "Terraform"
  }
}

# Attach the deployment policy to the role
resource "aws_iam_role_policy_attachment" "terraform_deploy" {
  role       = aws_iam_role.terraform_deploy.name
  policy_arn = aws_iam_policy.terraform_deploy.arn
}

# ----------------------------------------------------------------------------
# 3. OIDC Provider for GitHub Actions (Optional - for CI/CD)
# ----------------------------------------------------------------------------
resource "aws_iam_openid_connect_provider" "github_actions" {
  count = var.enable_github_actions_oidc ? 1 : 0

  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = {
    Name        = "GitHub Actions OIDC Provider"
    Application = var.app_name
    ManagedBy   = "Terraform"
  }
}

# GitHub Actions role that uses OIDC
resource "aws_iam_role" "github_actions" {
  count       = var.enable_github_actions_oidc ? 1 : 0
  name        = "${var.app_name}-github-actions"
  description = "Role for GitHub Actions to deploy ${var.app_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions[0].arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:*"
          }
        }
      }
    ]
  })

  max_session_duration = 3600

  tags = {
    Name        = "GitHub Actions Role"
    Application = var.app_name
    ManagedBy   = "Terraform"
  }
}

# Attach deployment policy to GitHub Actions role
resource "aws_iam_role_policy_attachment" "github_actions" {
  count      = var.enable_github_actions_oidc ? 1 : 0
  role       = aws_iam_role.github_actions[0].name
  policy_arn = aws_iam_policy.terraform_deploy.arn
}

# ----------------------------------------------------------------------------
# Data Sources
# ----------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

