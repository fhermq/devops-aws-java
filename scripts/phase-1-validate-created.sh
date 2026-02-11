#!/bin/bash

# Phase 1: State Infrastructure - Validation (Created)
# Checks that all Phase 1 resources were created successfully
# Validates: S3 buckets, DynamoDB tables, ECR repositories
# Usage: ./scripts/phase-1-validate-created.sh

set -e

echo ""
echo "=========================================="
echo "Phase 1 Validation (Created)"
echo "State Infrastructure Setup"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Counter for checks
PASSED=0
FAILED=0

AWS_REGION=${AWS_REGION:-us-east-1}
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")

if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo -e "${RED}✗ Unable to get AWS account ID. Check credentials.${NC}"
    exit 1
fi

echo "Account: $AWS_ACCOUNT_ID | Region: $AWS_REGION"
echo ""

# Check S3 Bucket
echo "Checking S3 Backend Bucket..."
if aws s3 ls "s3://devops-aws-java-terraform-state" 2>/dev/null > /dev/null; then
    echo -e "${GREEN}✓ S3 Bucket: devops-aws-java-terraform-state${NC}"
    ((PASSED++))
    
    # Check versioning
    VERSIONING=$(aws s3api get-bucket-versioning --bucket devops-aws-java-terraform-state --region $AWS_REGION --query 'Status' --output text 2>/dev/null || echo "")
    if [ "$VERSIONING" == "Enabled" ]; then
        echo -e "${GREEN}✓ S3 Versioning: Enabled${NC}"
        ((PASSED++))
    else
        echo -e "${YELLOW}⚠ S3 Versioning: Not enabled${NC}"
    fi
    
    # Check encryption
    ENCRYPTION=$(aws s3api get-bucket-encryption --bucket devops-aws-java-terraform-state --region $AWS_REGION 2>/dev/null | grep -q "AES256" && echo "Enabled" || echo "")
    if [ ! -z "$ENCRYPTION" ]; then
        echo -e "${GREEN}✓ S3 Encryption: Enabled${NC}"
        ((PASSED++))
    else
        echo -e "${YELLOW}⚠ S3 Encryption: Not configured${NC}"
    fi
else
    echo -e "${RED}✗ S3 Bucket: NOT FOUND${NC}"
    ((FAILED++))
fi
echo ""

# Check DynamoDB Table
echo "Checking DynamoDB Locks Table..."
if aws dynamodb describe-table --table-name terraform-locks --region $AWS_REGION 2>/dev/null > /dev/null; then
    TABLE_STATUS=$(aws dynamodb describe-table --table-name terraform-locks --region $AWS_REGION --query 'Table.TableStatus' --output text 2>/dev/null || echo "")
    
    if [ "$TABLE_STATUS" == "ACTIVE" ]; then
        echo -e "${GREEN}✓ DynamoDB Table: terraform-locks (ACTIVE)${NC}"
        ((PASSED++))
    else
        echo -e "${YELLOW}⚠ DynamoDB Table: terraform-locks (Status: $TABLE_STATUS)${NC}"
        ((PASSED++))
    fi
else
    echo -e "${RED}✗ DynamoDB Table: NOT FOUND${NC}"
    ((FAILED++))
fi
echo ""

# Check ECR Repository
echo "Checking ECR Repository..."
if aws ecr describe-repositories --repository-names devops-aws-java --region $AWS_REGION 2>/dev/null > /dev/null; then
    REPO_URI=$(aws ecr describe-repositories --repository-names devops-aws-java --region $AWS_REGION --query 'repositories[0].repositoryUri' --output text 2>/dev/null || echo "")
    echo -e "${GREEN}✓ ECR Repository: $REPO_URI${NC}"
    ((PASSED++))
    
    # Check lifecycle policy
    if aws ecr describe-lifecycle-policy --repository-name devops-aws-java --region $AWS_REGION 2>/dev/null > /dev/null; then
        echo -e "${GREEN}✓ ECR Lifecycle Policy: Configured${NC}"
        ((PASSED++))
    else
        echo -e "${YELLOW}⚠ ECR Lifecycle Policy: Not configured${NC}"
    fi
else
    echo -e "${RED}✗ ECR Repository: NOT FOUND${NC}"
    ((FAILED++))
fi
echo ""

# Check Terraform State File
echo "Checking Terraform State File..."
STATE_EXISTS=$(aws s3 ls s3://devops-aws-java-terraform-state/terraform.tfstate 2>/dev/null || echo "")

if [ ! -z "$STATE_EXISTS" ]; then
    echo -e "${GREEN}✓ Terraform State File: Exists in S3${NC}"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠ Terraform State File: Not yet created (will be created on first apply)${NC}"
fi
echo ""

# Summary
echo "=========================================="
echo "Phase 1 Validation Summary"
echo "=========================================="
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ Phase 1 Infrastructure Created Successfully!${NC}"
    echo -e "${GREEN}✓ State infrastructure ready for Terraform!${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Some checks failed. Please review the errors above.${NC}"
    echo ""
    exit 1
fi
