#!/bin/bash

# Phase 1: State Infrastructure - Setup S3 Backend
# Creates S3 bucket and DynamoDB table for Terraform state management and locking
# Usage: ./scripts/phase-1-setup-backend.sh

set -e

echo "=========================================="
echo "Setting up Terraform S3 Backend"
echo "=========================================="
echo ""

# Configuration
BUCKET_NAME="devops-aws-java-terraform-state"
TABLE_NAME="terraform-locks"
REGION="us-east-1"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "Configuration:"
echo "  S3 Bucket: $BUCKET_NAME"
echo "  DynamoDB Table: $TABLE_NAME"
echo "  Region: $REGION"
echo "  Account ID: $AWS_ACCOUNT_ID"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Step 1: Create S3 Bucket
echo "=========================================="
echo "Step 1: Creating S3 Bucket"
echo "=========================================="

if aws s3 ls "s3://$BUCKET_NAME" 2>/dev/null; then
    echo -e "${YELLOW}⚠ Bucket already exists: $BUCKET_NAME${NC}"
else
    echo "Creating bucket: $BUCKET_NAME"
    aws s3 mb "s3://$BUCKET_NAME" --region $REGION
    echo -e "${GREEN}✓ Bucket created${NC}"
fi
echo ""

# Step 2: Enable Versioning
echo "=========================================="
echo "Step 2: Enabling Versioning"
echo "=========================================="
echo "Enabling versioning on bucket..."
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled \
    --region $REGION
echo -e "${GREEN}✓ Versioning enabled${NC}"
echo ""

# Step 3: Enable Encryption
echo "=========================================="
echo "Step 3: Enabling Encryption"
echo "=========================================="
echo "Enabling server-side encryption..."
aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }' \
    --region $REGION
echo -e "${GREEN}✓ Encryption enabled${NC}"
echo ""

# Step 4: Block Public Access
echo "=========================================="
echo "Step 4: Blocking Public Access"
echo "=========================================="
echo "Blocking all public access..."
aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
    --region $REGION
echo -e "${GREEN}✓ Public access blocked${NC}"
echo ""

# Step 5: Create DynamoDB Table for Locking
echo "=========================================="
echo "Step 5: Creating DynamoDB Table for Locking"
echo "=========================================="

if aws dynamodb describe-table --table-name "$TABLE_NAME" --region $REGION 2>/dev/null; then
    echo -e "${YELLOW}⚠ Table already exists: $TABLE_NAME${NC}"
else
    echo "Creating DynamoDB table: $TABLE_NAME"
    aws dynamodb create-table \
        --table-name "$TABLE_NAME" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region $REGION
    
    echo "Waiting for table to be created..."
    aws dynamodb wait table-exists --table-name "$TABLE_NAME" --region $REGION
    echo -e "${GREEN}✓ DynamoDB table created${NC}"
fi
echo ""

# Step 6: Create ECR Repository
echo "=========================================="
echo "Step 6: Creating ECR Repository"
echo "=========================================="

ECR_REPO_NAME="devops-aws-java"

if aws ecr describe-repositories --repository-names "$ECR_REPO_NAME" --region $REGION 2>/dev/null > /dev/null; then
    echo -e "${YELLOW}⚠ ECR Repository already exists: $ECR_REPO_NAME${NC}"
else
    echo "Creating ECR repository: $ECR_REPO_NAME"
    aws ecr create-repository \
        --repository-name "$ECR_REPO_NAME" \
        --region $REGION \
        --image-scanning-configuration scanOnPush=true \
        --encryption-configuration encryptionType=AES256
    echo -e "${GREEN}✓ ECR repository created${NC}"
fi

# Set lifecycle policy to keep last 5 images
echo "Setting ECR lifecycle policy..."
aws ecr put-lifecycle-policy \
    --repository-name "$ECR_REPO_NAME" \
    --lifecycle-policy-text '{
        "rules": [
            {
                "rulePriority": 1,
                "description": "Keep last 5 images",
                "selection": {
                    "tagStatus": "any",
                    "countType": "imageCountMoreThan",
                    "countNumber": 5
                },
                "action": {
                    "type": "expire"
                }
            }
        ]
    }' \
    --region $REGION
echo -e "${GREEN}✓ Lifecycle policy configured${NC}"
echo ""

# Step 7: Summary
echo "=========================================="
echo "Backend Setup Complete!"
echo "=========================================="
echo ""
echo "S3 Bucket Configuration:"
echo "  Name: $BUCKET_NAME"
echo "  Region: $REGION"
echo "  Versioning: Enabled"
echo "  Encryption: AES256"
echo "  Public Access: Blocked"
echo ""
echo "DynamoDB Table Configuration:"
echo "  Name: $TABLE_NAME"
echo "  Region: $REGION"
echo "  Purpose: State locking"
echo ""
echo "ECR Repository Configuration:"
echo "  Name: $ECR_REPO_NAME"
echo "  Region: $REGION"
echo "  Image Scanning: Enabled"
echo "  Encryption: AES256"
echo "  Lifecycle Policy: Keep last 5 images"
echo ""
echo "Next steps:"
echo "  1. Run: ./scripts/phase-1-validate-created.sh"
echo "  2. Verify all Phase 1 resources created"
echo "  3. Push to main to trigger Phase 2 deployment"
echo ""
echo "=========================================="
