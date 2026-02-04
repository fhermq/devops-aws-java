# GitHub Actions OIDC Provider Setup

Quick reference for setting up GitHub Actions OIDC authentication with AWS.

## What is OIDC?

OIDC (OpenID Connect) allows GitHub Actions to authenticate to AWS without storing long-lived credentials. Instead:
- GitHub generates a short-lived token (~1 hour)
- GitHub sends it to AWS OIDC Provider
- AWS verifies and issues temporary credentials
- Credentials automatically expire

## One-Time Setup

Run this command **once** on your local machine:

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
  --region us-east-1
```

### Understanding the Parameters

- **`--url`**: GitHub's OIDC token endpoint (official GitHub URL)
- **`--client-id-list`**: AWS STS service (standard for GitHub Actions)
- **`--thumbprint-list`**: SHA-1 fingerprint of GitHub's SSL certificate (see below)
- **`--region`**: AWS region (must match your infrastructure)

### About the Thumbprint

The thumbprint (`6938fd4d98bab03faadb97b34396831e3780aea1`) is the SHA-1 hash of GitHub's SSL certificate. It's used by AWS to verify that OIDC tokens really come from GitHub (not a fake server).

**Verify the thumbprint is correct:**

```bash
openssl s_client -servername token.actions.githubusercontent.com \
  -connect token.actions.githubusercontent.com:443 \
  -showcerts < /dev/null 2>/dev/null | \
  openssl x509 -fingerprint -noout | \
  sed 's/://g' | \
  awk -F= '{print tolower($2)}'
```

Should output: `6938fd4d98bab03faadb97b34396831e3780aea1`

**Where this comes from:**
- GitHub's official documentation
- AWS documentation for GitHub OIDC setup
- Verified against GitHub's actual SSL certificate

## Verify It Worked

```bash
aws iam list-open-id-connect-providers
```

Should show:
```json
{
    "OpenIDConnectProviderList": [
        {
            "Arn": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
        }
    ]
}
```

## When to Run

- **Before**: First GitHub Actions workflow execution
- **Frequency**: Only once per AWS account
- **Location**: Run locally on your machine (not in GitHub Actions)

## If It Fails

### Error: "EntityAlreadyExists"
The provider already exists. This is fine - you can proceed.

### Error: "AccessDenied"
Your AWS credentials don't have IAM permissions. Use an account with admin access.

### Error: "InvalidInput"
Check that the URL and thumbprint are exactly as shown above.

## What Gets Created

- **OIDC Provider**: `arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com`
- **Trust Relationship**: Configured in Terraform IAM role
- **Permissions**: Limited to ECR push/pull and EKS deployment

## Security Benefits

✅ No long-lived credentials stored in GitHub
✅ Automatic credential rotation (1 hour)
✅ Clear audit trail (repo, branch, commit visible)
✅ Least privilege permissions
✅ Easy to revoke (delete role)

## Troubleshooting

### GitHub Actions Still Fails with "No OpenIDConnect provider found"

1. Verify provider was created:
   ```bash
   aws iam list-open-id-connect-providers
   ```

2. Check IAM role trust policy:
   ```bash
   aws iam get-role-policy --role-name github-actions-ecr-role --policy-name github-actions-ecr-policy
   ```

3. Re-run the workflow after provider is created

### How to Delete (if needed)

```bash
aws iam delete-open-id-connect-provider \
  --open-id-connect-provider-arn arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com
```

## References

- [GitHub Actions OIDC Documentation](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [AWS IAM OIDC Provider](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
- [Terraform AWS OIDC Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider)

---

**Last Updated:** February 4, 2026
