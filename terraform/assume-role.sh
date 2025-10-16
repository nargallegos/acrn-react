#!/bin/bash
# Helper script to assume the Terraform deployment role and export temporary credentials
# Usage: source assume-role.sh

set -e

# Configuration (update these after running terraform apply)
ROLE_ARN="${TERRAFORM_DEPLOY_ROLE_ARN:-arn:aws:iam::ACCOUNT_ID:role/acrn-react-terraform-deploy}"
EXTERNAL_ID="${TERRAFORM_DEPLOY_EXTERNAL_ID:-terraform-deploy-acrn}"
SESSION_NAME="terraform-deploy-$(date +%s)"
DURATION=3600  # 1 hour

echo "🔐 Assuming role: $ROLE_ARN"
echo "⏱️  Session duration: $DURATION seconds ($(($DURATION / 60)) minutes)"
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ Error: AWS CLI is not installed"
    echo "Install it from: https://aws.amazon.com/cli/"
    return 1
fi

# Check if jq is installed (for JSON parsing)
if ! command -v jq &> /dev/null; then
    echo "⚠️  Warning: jq is not installed. Using manual parsing."
    USE_JQ=false
else
    USE_JQ=true
fi

# Assume the role
echo "🔄 Requesting temporary credentials..."
CREDENTIALS=$(aws sts assume-role \
    --role-arn "$ROLE_ARN" \
    --role-session-name "$SESSION_NAME" \
    --external-id "$EXTERNAL_ID" \
    --duration-seconds "$DURATION" \
    2>&1)

if [ $? -ne 0 ]; then
    echo "❌ Error assuming role:"
    echo "$CREDENTIALS"
    return 1
fi

# Parse and export credentials
if [ "$USE_JQ" = true ]; then
    export AWS_ACCESS_KEY_ID=$(echo "$CREDENTIALS" | jq -r '.Credentials.AccessKeyId')
    export AWS_SECRET_ACCESS_KEY=$(echo "$CREDENTIALS" | jq -r '.Credentials.SecretAccessKey')
    export AWS_SESSION_TOKEN=$(echo "$CREDENTIALS" | jq -r '.Credentials.SessionToken')
    EXPIRATION=$(echo "$CREDENTIALS" | jq -r '.Credentials.Expiration')
else
    # Fallback parsing without jq
    export AWS_ACCESS_KEY_ID=$(echo "$CREDENTIALS" | grep -o '"AccessKeyId": "[^"]*' | sed 's/"AccessKeyId": "//')
    export AWS_SECRET_ACCESS_KEY=$(echo "$CREDENTIALS" | grep -o '"SecretAccessKey": "[^"]*' | sed 's/"SecretAccessKey": "//')
    export AWS_SESSION_TOKEN=$(echo "$CREDENTIALS" | grep -o '"SessionToken": "[^"]*' | sed 's/"SessionToken": "//')
    EXPIRATION=$(echo "$CREDENTIALS" | grep -o '"Expiration": "[^"]*' | sed 's/"Expiration": "//')
fi

# Verify we got credentials
if [ -z "$AWS_ACCESS_KEY_ID" ]; then
    echo "❌ Error: Failed to parse credentials"
    return 1
fi

# Verify the credentials work
echo "✅ Credentials obtained successfully!"
echo "📅 Expiration: $EXPIRATION"
echo ""

IDENTITY=$(aws sts get-caller-identity 2>&1)
if [ $? -eq 0 ]; then
    echo "🎯 Current AWS Identity:"
    echo "$IDENTITY"
    echo ""
    echo "✅ You are now authenticated as the deployment role!"
    echo "🚀 You can now run Terraform commands:"
    echo "   terraform plan"
    echo "   terraform apply"
    echo ""
    echo "⏰ Credentials will expire at: $EXPIRATION"
else
    echo "⚠️  Warning: Could not verify credentials"
    echo "$IDENTITY"
fi

# Optional: Set PS1 to show you're using assumed role
export PS1="(assumed-role) $PS1"

# ============================================================================
# IMPORTANT: This script must be SOURCED, not executed directly
# ============================================================================
# Correct:   source assume-role.sh
# Correct:   . assume-role.sh
# Wrong:     ./assume-role.sh  (won't export variables to your shell)
# ============================================================================

