# Setup Guide - Getting Started with DevOps Pipeline

Complete setup instructions for deploying the Java microservice DevOps pipeline on AWS.

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [AWS Configuration](#aws-configuration)
4. [GitHub Configuration](#github-configuration)
5. [Verification](#verification)
6. [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before starting, ensure you have:

- AWS Account with appropriate permissions
- AWS CLI installed and available
- Terraform >= 1.0
- kubectl
- Helm 3.x
- Docker
- Git
- GitHub account with repository created

### GitHub Actions OIDC Provider (Required for CI/CD)

Before running GitHub Actions workflows, you must set up OIDC authentication. This is a one-time setup:

1. **Create OIDC Provider** in AWS
2. **Create IAM Role** for GitHub Actions

See **[OIDC_SETUP.md](OIDC_SETUP.md)** for complete step-by-step instructions.

**Quick summary:**
```bash
# Step 1: Create OIDC provider
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
  --region us-east-1

# Step 2: Create IAM role (see OIDC_SETUP.md for full command)
# This creates the github-actions-ecr-role with proper permissions
```

Without this setup, GitHub Actions workflows will fail with: "No OpenIDConnect provider found"

---

## Initial Setup

### Step 1: Clone the Repository

```bash
git clone https://github.com/fhermq/devops-aws-java.git
cd devops-aws-java
```

### Step 2: Create Local Terraform Configuration

```bash
# Copy the template
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# Open in your editor
nano terraform/terraform.tfvars
```

### Step 3: Configure terraform/terraform.tfvars

Edit the file with your values:

```hcl
# REQUIRED: Your AWS account ID (12 digits)
aws_account_id       = "123456789012"

# REQUIRED: Your GitHub organization
github_org           = "fhermq"

# REQUIRED: Your repository name
github_repo          = "devops-aws-java"

# Optional: Adjust these if needed
aws_region           = "us-east-1"
ecr_repository_name  = "devops-aws-java"
image_retention_count = 5

# EKS Configuration
eks_cluster_name      = "devops-aws-java-cluster"
kubernetes_version    = "1.30"
vpc_cidr              = "10.0.0.0/26"
node_instance_types   = ["t3.small"]
node_desired_size     = 2
node_min_size         = 1
node_max_size         = 4
```

**Save and exit** (Ctrl+X, then Y, then Enter in nano)

---

## AWS Configuration

### Step 1: Get Your AWS Account ID

**Option A: Using AWS CLI**
```bash
aws sts get-caller-identity --query Account --output text
# Output: 123456789012
```

**Option B: Using AWS Console**
1. Go to https://console.aws.amazon.com/
2. Click your account name (top right)
3. Copy the Account ID

### Step 2: Configure AWS Credentials

```bash
# Configure AWS CLI
aws configure
```

When prompted, enter:
```
AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
Default region name [None]: us-east-1
Default output format [None]: json
```

### Step 3: Verify AWS Configuration

```bash
# Check credentials are configured
aws sts get-caller-identity

# Expected output:
# {
#     "UserId": "AIDAI...",
#     "Account": "123456789012",
#     "Arn": "arn:aws:iam::123456789012:user/your-user"
# }
```

---

## GitHub Configuration

### Step 1: Add GitHub Secret

1. Go to your GitHub repository
2. Click **Settings** (top right)
3. Click **Secrets and variables** (left sidebar)
4. Click **Actions**
5. Click **New repository secret** (green button)
6. Fill in:
   - **Name**: `AWS_ACCOUNT_ID`
   - **Value**: Your AWS account ID (e.g., `123456789012`)
7. Click **Add secret**

### Step 2: Verify GitHub Secret

```bash
# List secrets (requires GitHub CLI)
gh secret list

# Should show:
# AWS_ACCOUNT_ID  ***
```

---

## Verification

Run these checks before deploying:

### 1. Security Check

```bash
bash scripts/security-check.sh
```

**Expected**: All checks pass ✓

### 2. Verify Git Configuration

```bash
# Check that sensitive files are ignored
git check-ignore terraform/terraform.tfvars
git check-ignore .env

# Should output the file paths (meaning they're ignored)
```

### 3. Verify Terraform Configuration

```bash
# Validate Terraform syntax
terraform -chdir=terraform validate

# Should output: Success! The configuration is valid.
```

### 4. Verify AWS Credentials

```bash
# Check AWS credentials
aws sts get-caller-identity

# Should show your account info
```

### 5. Verify GitHub Secrets

```bash
# List GitHub secrets
gh secret list

# Should show AWS_ACCOUNT_ID
```

---

## File Locations Reference

### Local Files (On Your Computer)

```
~/.aws/credentials
├── AWS access key ID
├── AWS secret access key
└── Region

devops-aws-java/terraform/terraform.tfvars
├── AWS account ID
├── GitHub organization
└── GitHub repository name
```

### Remote Files (On GitHub)

```
GitHub Repository Settings
└── Secrets and variables
    └── AWS_ACCOUNT_ID (encrypted)
```

---

## What Each File Contains

### terraform/terraform.tfvars (Local Only - NOT Committed)
```hcl
# Your AWS account ID (12 digits)
aws_account_id = "123456789012"

# Your GitHub organization
github_org = "fhermq"

# Your repository name
github_repo = "devops-aws-java"

# Other configuration (same for everyone)
aws_region = "us-east-1"
eks_cluster_name = "devops-aws-java-cluster"
# ... etc
```

### ~/.aws/credentials (Local Only - NOT Committed)
```
[default]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
region = us-east-1
```

### GitHub Secrets (Encrypted on GitHub)
```
AWS_ACCOUNT_ID = 123456789012
```

---

## The Three Places for Credentials

When someone clones this project, they need to configure credentials in **three places**:

### 1. **Terraform Configuration** (Local File)
**File**: `terraform/terraform.tfvars`
- Contains: AWS account ID, GitHub org/repo
- Location: Your local machine
- Committed: ❌ No (in .gitignore)
- Created from: `terraform/terraform.tfvars.example`

### 2. **AWS Credentials** (Local Machine)
**File**: `~/.aws/credentials` (in your home directory)
- Contains: AWS access key ID, secret access key
- Location: Your local machine (home directory)
- Committed: ❌ No (never)
- Created by: `aws configure` command

### 3. **GitHub Secrets** (GitHub Repository)
**Location**: GitHub repository → Settings → Secrets and variables → Actions
- Contains: AWS account ID (encrypted)
- Location: GitHub servers
- Committed: ✅ Yes (encrypted)
- Used by: GitHub Actions workflow

---

## Setup Checklist

When setting up the project:

- [ ] Clone repository
- [ ] Create `terraform/terraform.tfvars` from `.example`
- [ ] Fill in AWS account ID in `terraform/terraform.tfvars`
- [ ] Fill in GitHub org/repo in `terraform/terraform.tfvars`
- [ ] Run `aws configure` to set up `~/.aws/credentials`
- [ ] Add `AWS_ACCOUNT_ID` secret to GitHub repository
- [ ] Run `bash scripts/security-check.sh`
- [ ] Verify with `aws sts get-caller-identity`
- [ ] Verify with `terraform -chdir=terraform validate`
- [ ] Ready to deploy!

---

## Before Pushing to GitHub

### Pre-Push Verification

Run this checklist before pushing to GitHub:

#### 1. Security Check
```bash
bash scripts/security-check.sh
```
**Expected**: All checks pass ✓

#### 2. Review Git Status
```bash
git status
```
**Expected**: 
- No `terraform/terraform.tfvars` (should be ignored)
- No `.env` files (should be ignored)
- No `kubeconfig` files (should be ignored)

#### 3. Review Changes
```bash
git diff --cached
```
**Expected**: 
- No AWS account IDs (except in examples/documentation)
- No credentials
- No private keys

#### 4. Verify .gitignore
```bash
git check-ignore terraform/terraform.tfvars
git check-ignore .env
git check-ignore kubeconfig
```
**Expected**: All return the file path (meaning they're ignored)

#### 5. List Files to Commit
```bash
git ls-files --others --exclude-standard
```
**Expected**: Should NOT include:
- `terraform/terraform.tfvars`
- `.env`
- `kubeconfig`
- `*.tfstate`
- `outputs.json`

### Files Being Committed

#### Safe to Commit ✅
- `.gitignore` - Git ignore rules
- `.github/workflows/deploy.yml` - Uses variables
- `helm/microservice/values.yaml` - Uses variables
- `terraform/*.tf` - Uses var. references
- `terraform/terraform.tfvars.example` - Template only
- All source code files
- Documentation files

#### NOT Being Committed ❌
- `terraform/terraform.tfvars` - Contains AWS account ID
- `.env` - Environment variables
- `kubeconfig` - Kubernetes config
- `*.tfstate` - Terraform state
- `outputs.json` - Terraform outputs
- `.aws/credentials` - AWS credentials

### Push to GitHub

Once all checks pass:

```bash
# Stage all changes
git add .

# Verify one more time
git status

# Commit
git commit -m "Initial commit: DevOps pipeline with security hardening"

# Push to GitHub
git push origin main
```

### Post-Push Verification

After pushing, verify:

1. **Check GitHub Actions**:
   - Go to: https://github.com/fhermq/devops-aws-java/actions
   - Should see workflow file: "Build and Deploy Microservice"

2. **Verify Secrets**:
   - Go to: Settings → Secrets and variables → Actions
   - Should see: `AWS_ACCOUNT_ID` (value hidden)

3. **Check Files**:
   - Go to: Code tab
   - Should NOT see `terraform/terraform.tfvars`
   - Should see `terraform/terraform.tfvars.example`

---

## Troubleshooting

### "terraform.tfvars: No such file or directory"
```bash
# Create it from the example
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

### "Unable to locate credentials"
```bash
# Configure AWS credentials
aws configure

# Verify it worked
aws sts get-caller-identity
```

### "GitHub Actions fails with 'role not found'"
1. Check GitHub secret is set: `gh secret list`
2. Check secret value is correct: Your AWS account ID
3. Check IAM role exists in AWS: `github-actions-ecr-role`

### "Terraform uses wrong account"
```bash
# Check what account Terraform will use
terraform -chdir=terraform plan | head -20

# Verify terraform.tfvars has correct account ID
cat terraform/terraform.tfvars | grep aws_account_id
```

### "terraform.tfvars is not in .gitignore"
```bash
# Verify .gitignore
cat .gitignore | grep tfvars

# Should show:
# *.tfvars
# !terraform/terraform.tfvars.example
```

### "AWS account ID found in files"
```bash
# Check which files have it
grep -r "444625565163" . --exclude-dir=.git --exclude-dir=.terraform

# Should only be in:
# - terraform/terraform.tfvars (not committed)
# - Documentation with YOUR_AWS_ACCOUNT_ID placeholder
```

### "GitHub Actions secret not working"
1. Verify secret is set: Settings → Secrets and variables → Actions
2. Verify secret name is exactly: `AWS_ACCOUNT_ID`
3. Verify secret value is your AWS account ID (12 digits)

---

## Security Reminders

✅ **DO:**
- Keep `terraform/terraform.tfvars` on your local machine only
- Keep `~/.aws/credentials` on your local machine only
- Use GitHub Secrets for CI/CD
- Rotate credentials regularly
- Use `.gitignore` to prevent accidental commits
- Run security checks before pushing

❌ **DON'T:**
- Commit `terraform/terraform.tfvars` to GitHub
- Commit `~/.aws/credentials` to GitHub
- Share your AWS account ID publicly
- Share your AWS access keys
- Hardcode credentials in code
- Push without running security checks

---

## Next Steps

1. **Deploy Infrastructure**: Follow [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
2. **Run E2E Tests**: Follow [E2E_TEST_PLAN.md](E2E_TEST_PLAN.md)
3. **Monitor Pipeline**: Check GitHub Actions for workflow runs
4. **Review Logs**: Check CloudWatch for application logs

---

**Last Updated:** February 3, 2026
