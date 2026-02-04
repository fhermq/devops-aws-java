# GitHub Secrets Setup for Terraform

Guide for setting up GitHub Secrets to securely pass Terraform variables to GitHub Actions.

## Why GitHub Secrets?

- ✅ Sensitive values never committed to git
- ✅ Encrypted storage on GitHub
- ✅ Automatic injection into workflows
- ✅ Easy to rotate
- ✅ Audit trail of access

## Required Secrets

Add these secrets to your GitHub repository:

### Step 1: Go to GitHub Secrets

1. Go to your GitHub repository
2. Click **Settings** (top right)
3. Click **Secrets and variables** (left sidebar)
4. Click **Actions**
5. Click **New repository secret** (green button)

### Step 2: Add Required Secrets (4 Only!)

Add **only these 4 sensitive secrets**:

| Secret Name | Value | Example |
|------------|-------|---------|
| `AWS_ACCOUNT_ID` | Your AWS account ID | `123456789012` |
| `AWS_REGION` | AWS region | `us-east-1` |
| `ORG_NAME` | Your GitHub organization | `fhermq` |
| `REPO_NAME` | Your repository name | `devops-aws-java` |

**That's it!** All other configuration comes from `terraform/terraform.tfvars.example`

### Step 3: Verify Secrets Are Set

```bash
# List secrets (requires GitHub CLI)
gh secret list
```

Should show 4 secrets with values hidden as `***`

---

## Getting Values from terraform.tfvars

If you already have `terraform/terraform.tfvars`, you can extract the sensitive values:

```bash
# Extract sensitive values to add as GitHub Secrets
grep "aws_account_id" terraform/terraform.tfvars
grep "aws_region" terraform/terraform.tfvars
grep "github_org" terraform/terraform.tfvars
grep "github_repo" terraform/terraform.tfvars
```

All other configuration (ECR, EKS, VPC, etc.) is already in `terraform/terraform.tfvars.example` and will be used automatically.

---

## How It Works

### Hybrid Approach: Secrets + Public Config

```
GitHub Repo
  ├── terraform/terraform.tfvars.example (public config) ✅
  │   ├── ecr_repository_name
  │   ├── eks_cluster_name
  │   ├── kubernetes_version
  │   ├── vpc_cidr
  │   └── ... (all public values)
  └── .github/workflows/terraform.yml
       ↓
GitHub Secrets (encrypted - 4 only!)
  ├── AWS_ACCOUNT_ID
  ├── AWS_REGION
  ├── GITHUB_ORG
  └── GITHUB_REPO
       ↓
Workflow creates terraform.tfvars at runtime
  ├── Copies public config from .example
  ├── Adds sensitive values from secrets
  ├── Runs Terraform
  ├── Deletes tfvars file (cleanup)
```

### Benefits

✅ **Only 4 secrets** instead of 13
✅ **Public config visible** in repository
✅ **Easy to change** public values without secrets
✅ **Secure** - sensitive data in secrets only
✅ **Transparent** - see what's being deployed

---

## Workflow Execution

When you run the Terraform workflow:

1. **Checkout code** - Gets repository files
2. **Create terraform.tfvars** - Generates from GitHub Secrets
3. **Terraform Init** - Initializes Terraform
4. **Terraform Plan** - Plans changes
5. **Terraform Apply** - Applies changes (if on main branch)
6. **Cleanup** - tfvars file is not committed

---

## Security Best Practices

✅ **DO:**
- Use GitHub Secrets for all sensitive values
- Rotate secrets regularly
- Use least privilege (only needed values)
- Review secret access in audit logs
- Use branch protection rules

❌ **DON'T:**
- Commit terraform.tfvars to git
- Share secrets in chat/email
- Use the same secrets across projects
- Store secrets in code comments
- Log secrets in workflow output

---

## Troubleshooting

### Workflow Fails: "terraform.tfvars: No such file or directory"

**Cause:** Secrets not set or workflow can't access them

**Solution:**
1. Verify all secrets are set: `gh secret list`
2. Check secret names match exactly (case-sensitive)
3. Re-run workflow after adding secrets

### Workflow Fails: "Invalid value for variable"

**Cause:** Secret value format is wrong

**Solution:**
1. Check the value format (e.g., `2` not `"2"` for numbers)
2. Verify no extra quotes or spaces
3. Check against terraform/terraform.tfvars.example

### Can't See Secrets in Workflow Logs

**Good!** This is intentional. GitHub masks secrets in logs for security.

If you need to debug:
```bash
# Add this to workflow (temporary)
- name: Debug secrets
  run: |
    echo "Account: ${{ secrets.AWS_ACCOUNT_ID }}"
    # GitHub will show as: Account: ***
```

---

## Rotating Secrets

To update a secret:

1. Go to GitHub → Settings → Secrets and variables → Actions
2. Click the secret name
3. Click **Update secret**
4. Enter new value
5. Click **Update secret**

Next workflow run will use the new value.

---

## References

- [GitHub Actions Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [GitHub CLI Secret Commands](https://cli.github.com/manual/gh_secret)
- [Terraform Variables Documentation](https://www.terraform.io/language/values/variables)

---

**Last Updated:** February 4, 2026
