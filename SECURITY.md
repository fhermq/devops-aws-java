# Security Guide

Comprehensive security documentation for the DevOps pipeline, including best practices, pre-commit checklist, and incident response procedures.

## 📋 Table of Contents

1. [Security Overview](#security-overview)
2. [OIDC Provider Setup](#oidc-provider-setup)
3. [Pre-Commit Security Checklist](#pre-commit-security-checklist)
4. [Sensitive Files Reference](#sensitive-files-reference)
5. [Verification Commands](#verification-commands)
6. [If You Accidentally Commit Secrets](#if-you-accidentally-commit-secrets)
7. [Best Practices](#best-practices)

---

## Security Overview

### ✅ Security Audit Complete

All sensitive information has been removed or replaced with variables. The repository is safe to push to GitHub.

### Changes Made

1. **Removed Hardcoded AWS Account IDs**
   - ✅ GitHub Actions workflow: Uses `${{ secrets.AWS_ACCOUNT_ID }}`
   - ✅ Helm values: Uses `--set` during deployment
   - ✅ Documentation: Uses `YOUR_AWS_ACCOUNT_ID` placeholders

2. **Created Configuration Templates**
   - ✅ `terraform/terraform.tfvars.example` - Template for Terraform variables
   - ✅ `.gitignore` - Excludes sensitive files from git

3. **Updated GitHub Actions Workflow**
   - ✅ All hardcoded account IDs replaced with `${{ env.AWS_ACCOUNT_ID }}`
   - ✅ AWS_ACCOUNT_ID sourced from GitHub Secrets
   - ✅ ECR registry URL built dynamically

4. **Updated Helm Configuration**
   - ✅ Image registry is empty in values.yaml (set via --set)
   - ✅ No hardcoded AWS account IDs

5. **Created Security Documentation**
   - ✅ `SECURITY.md` - This file
   - ✅ `scripts/security-check.sh` - Automated security verification

---

## OIDC Provider Setup

### Prerequisites: Create GitHub OIDC Provider

Before running GitHub Actions workflows, you must create the OIDC provider in your AWS account. This is a one-time setup.

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
  --region us-east-1
```

### Why This Is Needed

- **GitHub Actions needs to authenticate to AWS**
- **OIDC provider tells AWS to trust GitHub's tokens**
- **Without this, workflows fail with:** "No OpenIDConnect provider found"

### When to Run

- Before first GitHub Actions workflow execution
- Only needs to be done once per AWS account
- Run locally on your machine (not in GitHub Actions)

### Verify OIDC Provider Created

```bash
aws iam list-open-id-connect-providers
```

Should show:
```
{
    "OpenIDConnectProviderList": [
        {
            "Arn": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
        }
    ]
}
```

### How OIDC Works

```
GitHub Actions
    ↓
GitHub generates short-lived token (~1 hour)
    ↓
GitHub sends token to AWS OIDC Provider
    ↓
AWS verifies token signature using GitHub's public key
    ↓
AWS checks trust policy (repo, branch, etc.)
    ↓
AWS issues temporary credentials (~1 hour)
    ↓
GitHub Actions uses temporary credentials
    ↓
Credentials automatically expire
```

### Benefits vs Access Keys

| Aspect | Access Keys | OIDC |
|--------|------------|------|
| **Lifetime** | Long-lived (months/years) | Short-lived (1 hour) |
| **Rotation** | Manual | Automatic |
| **Audit Trail** | Hard to track | Clear: repo, branch, commit |
| **Compromise Risk** | High | Low |
| **Permissions** | Often too broad | Specific to role |

---

### ✅ Credentials & Secrets
- [ ] No AWS account IDs in code files (use variables instead)
- [ ] No AWS access keys or secret keys
- [ ] No private SSH keys or certificates
- [ ] No API tokens or passwords
- [ ] No database credentials
- [ ] No encryption keys

### ✅ Configuration Files
- [ ] `terraform/terraform.tfvars` is in `.gitignore` (use `terraform.tfvars.example` instead)
- [ ] `.env` files are in `.gitignore`
- [ ] `kubeconfig` files are in `.gitignore`
- [ ] AWS credentials file (`~/.aws/credentials`) is not committed

### ✅ GitHub Actions Secrets
- [ ] `AWS_ACCOUNT_ID` is set as a GitHub secret (not hardcoded)
- [ ] All AWS account IDs use `${{ secrets.AWS_ACCOUNT_ID }}` or `${{ env.AWS_ACCOUNT_ID }}`
- [ ] IAM role ARNs use variables instead of hardcoded values

### ✅ Terraform Files
- [ ] No hardcoded AWS account IDs in `.tf` files
- [ ] All sensitive values use `var.` references
- [ ] `terraform.tfvars` is excluded from git
- [ ] `terraform.tfstate` and `terraform.tfstate.backup` are excluded from git

### ✅ Helm Charts
- [ ] No hardcoded registry URLs in values files
- [ ] Image registry is set via `--set` during deployment
- [ ] No AWS credentials in Helm templates

### ✅ Documentation
- [ ] No real AWS account IDs in README or guides
- [ ] No real credentials in examples
- [ ] Use placeholder values like `YOUR_AWS_ACCOUNT_ID`

### ✅ Build Artifacts
- [ ] `target/` directory is in `.gitignore`
- [ ] `dist/` directory is in `.gitignore`
- [ ] `build/` directory is in `.gitignore`
- [ ] Docker images are not committed

### ✅ IDE & OS Files
- [ ] `.vscode/` is in `.gitignore`
- [ ] `.idea/` is in `.gitignore`
- [ ] `.DS_Store` is in `.gitignore`
- [ ] `*.swp` and `*.swo` are in `.gitignore`

---

## Sensitive Files Reference

### Files That Should NOT Be Committed

| File | Contains | Why |
|------|----------|-----|
| `terraform/terraform.tfvars` | AWS account ID, GitHub org | Contains sensitive configuration |
| `.env` | Environment variables | May contain secrets |
| `.aws/credentials` | AWS access keys | Contains authentication credentials |
| `kubeconfig` | Kubernetes cluster config | Contains cluster authentication |
| `*.tfstate` | Terraform state | May contain sensitive data |
| `*.key`, `*.pem` | Private keys | Cryptographic secrets |
| `outputs.json` | Terraform outputs | May contain sensitive values |

### Files That SHOULD Be Committed

| File | Purpose |
|------|---------|
| `terraform/terraform.tfvars.example` | Template for tfvars |
| `.gitignore` | Git ignore rules |
| `SECURITY.md` | Security documentation |
| All `.tf` files | Infrastructure code (with variables) |
| All Helm chart files | Kubernetes deployment templates |
| `.github/workflows/deploy.yml` | CI/CD workflow (with variables) |

---

## Verification Commands

Run these before pushing to GitHub:

### Check for AWS Account IDs
```bash
grep -r "[0-9]\{12\}" . --exclude-dir=.git --exclude-dir=.terraform --exclude="*.tfstate*" --exclude="outputs.json" | grep -v "YOUR_AWS_ACCOUNT_ID" | grep -v ".example"
```
**Expected**: No output (or only in documentation with placeholders)

### Check for AWS Access Keys
```bash
grep -r "AKIA" . --exclude-dir=.git --exclude-dir=.terraform
```
**Expected**: No output

### Check for Private Keys
```bash
find . -name "*.key" -o -name "*.pem" | grep -v ".terraform"
```
**Expected**: No output

### Check Git Status
```bash
git status
```
**Expected**: 
- No `terraform/terraform.tfvars`
- No `.env` files
- No `kubeconfig` files

### Verify .gitignore is Working
```bash
git check-ignore terraform/terraform.tfvars
git check-ignore .env
git check-ignore kubeconfig
```
**Expected**: All return the file path (meaning they're ignored)

### Run Automated Security Check
```bash
bash scripts/security-check.sh
```
**Expected**: All checks pass ✓

---

## If You Accidentally Commit Secrets

### Immediate Actions

1. **Immediately rotate the credentials** in AWS
   - Delete the compromised access keys
   - Create new access keys
   - Update local `~/.aws/credentials`

2. **Remove the file from git history**:
   ```bash
   git filter-branch --tree-filter 'rm -f terraform/terraform.tfvars' HEAD
   git push origin --force-with-lease
   ```

3. **Update GitHub Actions secrets** if needed
   - Go to Settings → Secrets and variables → Actions
   - Update `AWS_ACCOUNT_ID` if it was exposed

4. **Notify your team** of the security incident
   - Explain what was exposed
   - Provide timeline of exposure
   - Confirm credentials have been rotated

### Prevention

- Always run `bash scripts/security-check.sh` before committing
- Review `git diff --cached` before pushing
- Use `.gitignore` to prevent accidental commits
- Enable branch protection on main branch
- Require code reviews before merging

---

## Best Practices

### Credentials Management

1. ✅ **Use GitHub Secrets** for all sensitive values
   - Store AWS account ID in GitHub Secrets
   - Reference via `${{ secrets.AWS_ACCOUNT_ID }}`

2. ✅ **Use Terraform Variables** for configuration
   - Store in `terraform/terraform.tfvars` (local only)
   - Reference via `var.aws_account_id`

3. ✅ **Use `.example` files** as templates
   - Commit `terraform/terraform.tfvars.example`
   - Don't commit `terraform/terraform.tfvars`

4. ✅ **Use IAM roles** instead of access keys when possible
   - Use OIDC for GitHub Actions
   - Use instance profiles for EC2

### Code Review

5. ✅ **Review `.gitignore`** before committing
   - Ensure sensitive files are ignored
   - Check for new file types that should be ignored

6. ✅ **Use `git diff`** to check what you're committing
   - Review all changes before pushing
   - Look for accidentally added credentials

7. ✅ **Enable branch protection** on main branch
   - Require code reviews before merging
   - Require status checks to pass

### Credential Rotation

8. ✅ **Rotate credentials regularly**
   - AWS access keys: Every 90 days
   - GitHub tokens: Every 6 months
   - Database passwords: Every 90 days

9. ✅ **Use MFA** on AWS account
   - Enable MFA on root account
   - Enable MFA on IAM users

### Monitoring

10. ✅ **Monitor for exposed credentials**
    - Use AWS CloudTrail for audit logs
    - Use GitHub secret scanning
    - Use third-party tools like GitGuardian

---

## Sensitive Information Locations

### AWS Account ID
- **Where it's used**: GitHub Actions, Terraform, Helm
- **How it's protected**: 
  - GitHub Actions: `${{ secrets.AWS_ACCOUNT_ID }}`
  - Terraform: `var.aws_account_id` (in tfvars, which is .gitignored)
  - Helm: `--set image.registry=...` (passed at runtime)
- **Who has access**: Only you (local) and GitHub Actions (via secrets)

### AWS Credentials
- **Where they're stored**: `~/.aws/credentials` (local machine only)
- **How they're protected**: Not committed to git
- **How they're used**: AWS CLI and Terraform use them locally
- **Who has access**: Only you (local machine)

### GitHub Organization
- **Where it's used**: Terraform OIDC configuration
- **How it's protected**: In tfvars (which is .gitignored)
- **Public info**: Yes, it's your GitHub org name
- **Who has access**: Everyone (it's public)

---

## Files Excluded from Git

These files are in `.gitignore` and will NOT be committed:

```
terraform/terraform.tfvars          # Contains AWS account ID
.env                                # Environment variables
.aws/credentials                    # AWS credentials
kubeconfig                          # Kubernetes config
*.tfstate                           # Terraform state
*.tfstate.backup                    # Terraform state backup
outputs.json                        # Terraform outputs
```

---

## Files Safe to Commit

These files are safe and should be committed:

```
terraform/terraform.tfvars.example  # Template (no secrets)
.gitignore                          # Git ignore rules
.github/workflows/deploy.yml        # Uses variables, not hardcoded values
helm/microservice/values.yaml       # Uses variables
SECURITY.md                         # Security documentation
scripts/security-check.sh           # Security verification script
```

---

## Security Incident Response

### If Credentials Are Exposed

1. **Assess the damage**
   - What credentials were exposed?
   - How long were they exposed?
   - Who had access to the repository?

2. **Contain the incident**
   - Rotate all exposed credentials immediately
   - Revoke any active sessions
   - Update GitHub Secrets

3. **Investigate**
   - Check AWS CloudTrail for unauthorized access
   - Check GitHub audit logs for suspicious activity
   - Review git history for when credentials were added

4. **Remediate**
   - Remove credentials from git history
   - Update all systems using the old credentials
   - Implement additional security controls

5. **Communicate**
   - Notify your team
   - Notify affected users
   - Document the incident

---

## Security Checklist for New Team Members

When a new team member joins:

- [ ] Provide them with [SETUP.md](SETUP.md)
- [ ] Have them create `terraform/terraform.tfvars` from `.example`
- [ ] Have them run `aws configure`
- [ ] Have them add `AWS_ACCOUNT_ID` to GitHub Secrets
- [ ] Have them run `bash scripts/security-check.sh`
- [ ] Have them review this security guide
- [ ] Have them sign security agreement (if applicable)

---

## Additional Resources

- [AWS Security Best Practices](https://aws.amazon.com/security/best-practices/)
- [GitHub Security Best Practices](https://docs.github.com/en/code-security)
- [Terraform Security Best Practices](https://www.terraform.io/docs/cloud/security/index.html)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)

---

**Last Updated:** February 3, 2026
**Security Audit Date:** February 3, 2026
