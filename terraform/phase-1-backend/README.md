# Phase 1: Backend Infrastructure

This Terraform configuration creates the backend infrastructure for managing Terraform state across all phases.

## Overview

This module creates:
- S3 bucket for Terraform state storage with versioning and encryption
- DynamoDB table for Terraform state locking
- ECR repository for Docker images
- IAM policy for GitHub Actions access

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- AWS account with appropriate permissions

## File Structure

```
.
├── main.tf                 # Provider configuration
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── s3.tf                   # S3 bucket configuration
├── dynamodb.tf             # DynamoDB table configuration
├── ecr.tf                  # ECR repository configuration
├── iam.tf                  # IAM policies
├── terraform.tfvars.example # Example variables file
└── README.md               # This file
```

## Usage

### 1. Initialize Terraform

```bash
cd terraform/phase-1-backend
terraform init
```

### 2. Create terraform.tfvars

```bash
cp terraform.tfvars.example terraform.tfvars
```

### 3. Plan the deployment

```bash
terraform plan
```

### 4. Apply the configuration

```bash
terraform apply
```

## Outputs

The configuration outputs:
- `s3_bucket_name` - S3 bucket name for state storage
- `s3_bucket_arn` - S3 bucket ARN
- `dynamodb_table_name` - DynamoDB table name for locking
- `dynamodb_table_arn` - DynamoDB table ARN
- `ecr_repository_name` - ECR repository name
- `ecr_repository_uri` - ECR repository URI

## Security Features

- **S3 Encryption**: AES256 encryption enabled
- **S3 Versioning**: Enabled for state file protection
- **Public Access**: Blocked on S3 bucket
- **State Locking**: DynamoDB table prevents concurrent modifications
- **Logging**: S3 access logs enabled for audit trail
- **ECR Scanning**: Image scanning on push enabled

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

## Notes

- This is a one-time setup phase
- State files are stored in S3 with versioning enabled
- DynamoDB table prevents concurrent Terraform operations
- ECR repository is used by Phase 2 and Phase 3 deployments

## Support

For issues or questions, refer to:
- [AWS S3 Documentation](https://docs.aws.amazon.com/s3/)
- [AWS DynamoDB Documentation](https://docs.aws.amazon.com/dynamodb/)
- [AWS ECR Documentation](https://docs.aws.amazon.com/ecr/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
