#!/bin/bash

# Phase 1: State Infrastructure - Check for Orphaned Resources
# Identifies AWS resources created outside of Terraform state
# Checks: S3 buckets, DynamoDB tables, ECR repositories
# Usage: ./scripts/phase-1-check-orphaned.sh

set -e

echo "=========================================="
echo "Phase 1: Check for Orphaned Resources"
echo "State Infrastructure (S3, DynamoDB, ECR)"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get AWS Account ID and Region
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=${AWS_REGION:-us-east-1}

echo "Account ID: $AWS_ACCOUNT_ID"
echo "Region: $AWS_REGION"
echo ""

# Check S3 Buckets
echo "=========================================="
echo "S3 Buckets"
echo "=========================================="
S3_BUCKETS=$(aws s3 ls | grep devops-aws-java || echo "")

if [ -z "$S3_BUCKETS" ]; then
  echo -e "${GREEN}✓ No orphaned S3 buckets found${NC}"
else
  echo -e "${YELLOW}Found S3 buckets:${NC}"
  echo "$S3_BUCKETS"
fi
echo ""

# Check DynamoDB Tables
echo "=========================================="
echo "DynamoDB Tables"
echo "=========================================="
DYNAMODB_TABLES=$(aws dynamodb list-tables --region $AWS_REGION --query 'TableNames[?contains(@, `terraform`)]' --output text 2>/dev/null || echo "")

if [ -z "$DYNAMODB_TABLES" ]; then
  echo -e "${GREEN}✓ No orphaned DynamoDB tables found${NC}"
else
  echo -e "${YELLOW}Found DynamoDB tables:${NC}"
  for table in $DYNAMODB_TABLES; do
    echo "  - $table"
  done
fi
echo ""

# Check ECR Repositories
echo "=========================================="
echo "ECR Repositories"
echo "=========================================="
ECR_REPOS=$(aws ecr describe-repositories --region $AWS_REGION --query 'repositories[*].repositoryName' --output text 2>/dev/null || echo "")

if [ -z "$ECR_REPOS" ]; then
  echo -e "${GREEN}✓ No ECR repositories found${NC}"
else
  echo -e "${YELLOW}Found ECR repositories:${NC}"
  for repo in $ECR_REPOS; do
    echo "  - $repo"
  done
fi
echo ""

# Check Terraform State Files in S3
echo "=========================================="
echo "Terraform State Files"
echo "=========================================="
STATE_FILES=$(aws s3 ls s3://devops-aws-java-terraform-state/ 2>/dev/null || echo "")

if [ -z "$STATE_FILES" ]; then
  echo -e "${GREEN}✓ No Terraform state files found${NC}"
else
  echo -e "${GREEN}Found Terraform state files:${NC}"
  echo "$STATE_FILES"
fi
echo ""

# Summary
echo "=========================================="
echo "Phase 1 Orphaned Resources Summary"
echo "=========================================="
echo ""
echo "To clean up orphaned Phase 1 resources:"
echo ""
echo "1. Delete S3 Bucket:"
echo "   aws s3 rb s3://devops-aws-java-terraform-state --force"
echo ""
echo "2. Delete DynamoDB Table:"
echo "   aws dynamodb delete-table --table-name terraform-locks --region $AWS_REGION"
echo ""
echo "3. Delete ECR Repository:"
echo "   aws ecr delete-repository --repository-name devops-aws-java --force --region $AWS_REGION"
echo ""
echo "=========================================="
