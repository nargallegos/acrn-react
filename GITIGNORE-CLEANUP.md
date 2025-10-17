# ⚠️ IMPORTANT: Git Cleanup Required

## Files Currently Tracked That Should Be Removed

The following files are currently tracked in git but should NOT be committed according to best practices:

### 🔴 CRITICAL - Contains Sensitive Data

1. **`terraform/terraform.tfvars`**
   - **Risk:** Contains your AWS configuration (hosted_zone_id, potentially secrets)
   - **Action Required:** Remove from git history immediately

### 📝 Personal Notes (Lower Risk)

2. **`TODO.md`**
   - Personal notes, not part of the project
   
3. **`GEMINI.md`**
   - Personal notes, not part of the project

## 🛠️ Cleanup Steps

### Step 1: Stop Tracking These Files

Run these commands to remove them from git tracking (files stay on disk):

```bash
# Remove from git tracking but keep the files locally
git rm --cached terraform/terraform.tfvars
git rm --cached TODO.md
git rm --cached GEMINI.md

# Commit the removal
git commit -m "chore: remove sensitive and personal files from git tracking"
```

### Step 2: Create Example Files (Optional)

Create example files for other developers:

```bash
# Create a template for terraform.tfvars
cat > terraform/terraform.tfvars.example << 'EOF'
# Terraform Variables - Copy this to terraform.tfvars and fill in your values

aws_region     = "us-east-1"
app_name       = "acrn-react"
domain_name    = "your-domain.example.com"
hosted_zone_id = "Z1234567890ABC"  # Get with: aws route53 list-hosted-zones

# Security: External ID for role assumption
terraform_deploy_external_id = "terraform-deploy-acrn"

# Optional: For remote state (recommended for teams)
terraform_state_bucket = ""
terraform_lock_table   = ""

# Optional: Enable GitHub Actions OIDC (no secrets!)
enable_github_actions_oidc = false
github_repo                = ""  # e.g., "yourusername/acrn-react"
EOF

# Add the example file to git
git add terraform/terraform.tfvars.example
git commit -m "docs: add terraform.tfvars.example template"
```

### Step 3: Clean Git History (IMPORTANT for terraform.tfvars)

Since `terraform.tfvars` may contain sensitive data and is in your git history, you should clean it:

#### Option A: Simple Removal (For Recent Commits)

If the file was added recently and not pushed to a shared repository:

```bash
# Remove from all history
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch terraform/terraform.tfvars" \
  --prune-empty --tag-name-filter cat -- --all

# Clean up
rm -rf .git/refs/original/
git reflog expire --expire=now --all
git gc --prune=now --aggressive
```

#### Option B: Using BFG Repo-Cleaner (Recommended for Large Repos)

```bash
# Install BFG
# On macOS: brew install bfg
# On Linux: Download from https://rtyley.github.io/bfg-repo-cleaner/

# Clean the file from history
bfg --delete-files terraform.tfvars

# Clean up
git reflog expire --expire=now --all
git gc --prune=now --aggressive
```

#### Option C: If Already Pushed to Remote

⚠️ **WARNING:** This rewrites history and requires force push!

```bash
# After cleaning with Option A or B:
git push origin --force --all
git push origin --force --tags
```

**Note:** Coordinate with your team before force pushing!

### Step 4: Verify Cleanup

```bash
# Check that files are no longer tracked
git ls-files | grep -E '(terraform.tfvars|TODO.md|GEMINI.md)'
# Should return nothing

# Verify files are ignored
git status
# Should not show these files as untracked
```

### Step 5: Consider Rotating Credentials (If Exposed)

If `terraform.tfvars` was pushed to a public/shared repository and contained:

- [ ] AWS Account ID - Low risk, but good to be aware
- [ ] Hosted Zone ID - Low risk
- [ ] External ID - **Rotate it!** Update in terraform.tfvars and redeploy
- [ ] Any actual AWS credentials - **Immediately disable those credentials!**

To rotate the external ID:

```bash
# Update terraform/terraform.tfvars
terraform_deploy_external_id = "new-unique-external-id-$(date +%s)"

# Redeploy IAM roles
cd terraform/
terraform apply
```

## ✅ Verification Checklist

After cleanup:

- [ ] `git ls-files` doesn't show sensitive files
- [ ] `git status` doesn't show ignored files as untracked
- [ ] `.gitignore` is comprehensive
- [ ] Example files created for team reference
- [ ] Git history cleaned (if sensitive data was committed)
- [ ] Remote repository force-pushed (if needed)
- [ ] Credentials rotated (if they were exposed)
- [ ] Team notified (if this is a shared repo)

## 🔒 Prevention

To prevent future accidents, install git-secrets:

```bash
# macOS
brew install git-secrets

# Initialize in your repo
cd /home/cele/One-Drive/Projects/acrn-iac/acrn-react
git secrets --install
git secrets --register-aws

# This will prevent committing AWS credentials
```

## 📚 Additional Resources

- [GitHub: Removing Sensitive Data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)
- [BFG Repo-Cleaner](https://rtyley.github.io/bfg-repo-cleaner/)
- [git-secrets](https://github.com/awslabs/git-secrets)
- [AWS: What to Do If You Accidentally Expose Credentials](https://aws.amazon.com/premiumsupport/knowledge-center/delete-keys-compromised/)

## ⚡ Quick Commands Reference

```bash
# Remove files from tracking (keep locally)
git rm --cached terraform/terraform.tfvars TODO.md GEMINI.md
git commit -m "chore: remove sensitive files from tracking"

# Add .terraform.lock.hcl (should be committed)
git add terraform/.terraform.lock.hcl
git commit -m "chore: add Terraform lock file for version consistency"

# Create example template
git add terraform/terraform.tfvars.example
git commit -m "docs: add configuration template"

# Verify
git status
```

---

**Priority:** 🔴 **HIGH** - Handle terraform.tfvars immediately if it's been pushed to any remote repository!

