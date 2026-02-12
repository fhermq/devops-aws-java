# Terraform Infrastructure as Code

This directory contains all Terraform configurations for the DevOps AWS Java Pipeline project, organized by deployment phases.

## Project Structure

```
terraform/
├── phase-1-backend/                    # Phase 1: Backend infrastructure
│   ├── main.tf                         # Provider configuration
│   ├── variables.tf                    # Input variables
│   ├── outputs.tf                      # Output values
│   ├── s3.tf                           # S3 bucket for state storage
│   ├── dynamodb.tf                     # DynamoDB table for state locking
│   ├── ecr.tf                          # ECR repository for Docker images
│   ├── iam.tf                          # IAM policies for GitHub Actions
│   ├── terraform.tfvars.example        # Example variables file
│   ├── .gitignore                      # Git exclusions
│   └── README.md                       # Phase 1 documentation
│
├── phase-2-eks/                        # Phase 2: EKS cluster infrastructure
│   ├── main.tf                         # Provider and backend configuration
│   ├── variables.tf                    # Input variables
│   ├── outputs.tf                      # Output values
│   ├── locals.tf                       # Local values and common tags
│   ├── data.tf                         # Data sources (availability zones)
│   ├── vpc.tf                          # VPC, subnets, route tables, IGW
│   ├── eks.tf                          # EKS cluster and node group
│   ├── iam.tf                          # IAM roles and policies
│   ├── terraform.tfvars.example        # Example variables file
│   ├── .gitignore                      # Git exclusions
│   ├── .terraform.lock.hcl             # Dependency lock file
│   └── README.md                       # Phase 2 documentation
│
├── backend.tf                          # Root backend configuration (references phase-1-backend)
├── terraform.tfvars.example            # Root example variables file
├── .gitignore                          # Root git exclusions
├── .terraform.lock.hcl                 # Root dependency lock file
├── README.md                           # This file
└── EKS_DEPLOYMENT_GUIDE.md             # EKS deployment guide
```

## Deployment Phases

### Phase 1: Backend Infrastructure (One-time setup)

Creates the foundation for Terraform state management and container registry:

**Resources created:**
- S3 bucket: `devops-aws-java-terraform-state` (with versioning and encryption)
- DynamoDB table: `terraform-locks` (for state locking)
- ECR repository: `devops-aws-java` (for Docker images)
- IAM policy: `terraform-backend-access` (for GitHub Actions)

**Manual deployment:**
```bash
cd terraform/phase-1-backend
terraform init
terraform plan
terraform apply
```

**Or use the automated script:**
```bash
./scripts/phase-1-setup-backend.sh
```

**Validation:**
```bash
./scripts/phase-1-validate-created.sh
```

### Phase 2: EKS Cluster Infrastructure

Deploys the Kubernetes infrastructure on AWS:

**Resources created:**
- VPC: `10.0.0.0/16` with public and private subnets across 2 AZs
- EKS Cluster: `devops-aws-java-cluster` (Kubernetes 1.30)
- Node Group: 2 t3.small instances (auto-scaling 1-4)
- IAM roles: Cluster role and node role with required policies
- Network Load Balancer: Created by Kubernetes Load Balancer Controller
- Security Groups: For cluster and node communication

**Automated via GitHub Actions** (when code is pushed to main):
- Triggered by changes to `terraform/phase-2-eks/**`
- Runs plan, apply, and validation automatically

**Manual deployment:**
```bash
cd terraform/phase-2-eks
terraform init
terraform plan
terraform apply
```

**Validation:**
```bash
./scripts/phase-2-validate-created.sh
```

**Cleanup:**
```bash
terraform -chdir=terraform/phase-2-eks destroy -auto-approve
./scripts/phase-2-validate-destroyed.sh
```

## State Management

Terraform state is stored remotely in AWS for team collaboration and safety:

- **State Storage**: S3 bucket `devops-aws-java-terraform-state`
  - Versioning enabled for recovery
  - Encryption enabled (AES256)
  - Public access blocked
  - Logging enabled for audit trail

- **State Locking**: DynamoDB table `terraform-locks`
  - Prevents concurrent modifications
  - Automatic lock timeout: 30 seconds

- **State Files**:
  - Root state: `s3://devops-aws-java-terraform-state/terraform.tfstate`
  - Phase 2 state: `s3://devops-aws-java-terraform-state/phase-2-eks/terraform.tfstate`

**Important:** Never commit `terraform.tfvars` or state files to version control. Use `.gitignore` to exclude them.

## Best Practices Applied

### Code Organization
✅ Separated concerns by file (vpc.tf, eks.tf, iam.tf, s3.tf, dynamodb.tf, ecr.tf)
✅ Centralized variables (variables.tf)
✅ Consolidated outputs (outputs.tf)
✅ Local values for reusability (locals.tf)
✅ Data sources organized (data.tf)

### State Management
✅ Remote state in S3 with versioning and encryption
✅ State locking with DynamoDB
✅ Separate state files per phase
✅ terraform.tfvars excluded from version control

### Configuration
✅ Proper backend configuration in main.tf
✅ .terraform.lock.hcl for reproducibility
✅ terraform.tfvars.example for documentation
✅ .gitignore at root and phase levels

### Documentation
✅ README.md at root and phase levels
✅ Inline comments in Terraform files
✅ Clear variable descriptions
✅ Output descriptions for clarity

### Security
✅ IAM policies with least privilege
✅ Encryption enabled for sensitive data
✅ Public access blocked on S3
✅ Account validation safeguard in Phase 2

## Common Commands

### Phase 1: Backend Setup
```bash
# Initialize
cd terraform/phase-1-backend
terraform init

# Plan
terraform plan

# Apply
terraform apply

# Validate
../scripts/phase-1-validate-created.sh
```

### Phase 2: EKS Deployment
```bash
# Initialize
cd terraform/phase-2-eks
terraform init

# Plan
terraform plan

# Apply
terraform apply

# Get outputs
terraform output

# Validate
../scripts/phase-2-validate-created.sh

# Destroy
terraform destroy -auto-approve
../scripts/phase-2-validate-destroyed.sh
```

### Using -chdir flag (from root)
```bash
# Plan Phase 2
terraform -chdir=terraform/phase-2-eks plan

# Apply Phase 2
terraform -chdir=terraform/phase-2-eks apply

# Destroy Phase 2
terraform -chdir=terraform/phase-2-eks destroy -auto-approve

# View outputs
terraform -chdir=terraform/phase-2-eks output -json
```

## Troubleshooting

### Backend initialization fails
**Problem:** `Error: error reading S3 Bucket in account`
- Ensure Phase 1 backend is deployed first
- Check S3 bucket exists: `aws s3 ls | grep devops-aws-java-terraform-state`
- Check DynamoDB table exists: `aws dynamodb list-tables | grep terraform-locks`
- Verify AWS credentials are configured: `aws sts get-caller-identity`

### State lock timeout
**Problem:** `Error: Error acquiring the state lock`
- Check for stuck locks: `aws dynamodb scan --table-name terraform-locks`
- Force unlock if necessary: `terraform force-unlock <LOCK_ID>`
- Wait 30 seconds for automatic timeout

### Resource creation timeout
**Problem:** Resources stuck in "Creating" state
- EKS cluster creation: 10-15 minutes (normal)
- Node group creation: 5-10 minutes (normal)
- Check AWS console for detailed status
- Check CloudFormation events for errors

### Subnet deletion stuck
**Problem:** `DependencyViolation: The subnet has dependencies and cannot be deleted`
- Check for Network Load Balancers: `aws elbv2 describe-load-balancers --query 'LoadBalancers[*].[LoadBalancerName,Type]'`
- Delete NLBs manually: `aws elbv2 delete-load-balancer --load-balancer-arn <ARN>`
- Then retry destroy

### VPC deletion stuck
**Problem:** `DependencyViolation: The vpc has dependencies and cannot be deleted`
- Check for remaining resources: `aws ec2 describe-route-tables --filters "Name=vpc-id,Values=<VPC_ID>"`
- Check for security groups: `aws ec2 describe-security-groups --filters "Name=vpc-id,Values=<VPC_ID>"`
- Delete dependencies manually before retrying

### Account validation fails
**Problem:** `ERROR: Attempting to deploy to account X, but terraform.tfvars specifies account Y`
- Verify AWS_ACCOUNT_ID in terraform.tfvars matches your account
- Check AWS credentials: `aws sts get-caller-identity`
- Ensure you're deploying to the correct account

## Security Considerations

### State File Security
- State files contain sensitive information (passwords, tokens, private keys)
- Always stored encrypted in S3 (AES256)
- Never commit state files to version control
- Use `.gitignore` to exclude `*.tfstate` and `*.tfvars`

### Access Control
- Use IAM roles for GitHub Actions (OIDC authentication)
- Never use long-lived AWS access keys
- Restrict IAM permissions to minimum required
- Enable MFA for AWS console access

### Secrets Management
- Never commit `terraform.tfvars` to version control
- Use GitHub Secrets for sensitive values
- Rotate credentials regularly
- Audit IAM permissions quarterly

### Network Security
- VPC uses private subnets for internal resources
- Public subnets only for load balancers
- Security groups restrict traffic to necessary ports
- Network ACLs provide additional layer of protection

### Compliance
- Enable CloudTrail for audit logging
- Enable S3 access logging
- Tag all resources for cost tracking
- Regular security assessments recommended

## Support

For detailed information about each phase:
- [Phase 1 Backend README](./phase-1-backend/README.md)
- [Phase 2 EKS README](./phase-2-eks/README.md)

For AWS documentation:
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [AWS S3 Documentation](https://docs.aws.amazon.com/s3/)
