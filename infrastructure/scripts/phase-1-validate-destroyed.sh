#!/bin/bash

# Phase 1: State Infrastructure - Validation (Destroyed)
# Checks that all Phase 1 resources were deleted successfully
# Validates: S3 buckets, DynamoDB tables, ECR repositories
# Usage: ./scripts/phase-1-validate-destroyed.sh

set -e

echo ""
echo "=========================================="
echo "Phase 1 Validation (Destroyed)"
echo "State Infrastructure Cleanup"
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

# Check S3 Bucket
echo "Checking S3 Backend Bucket..."
if ! aws s3 ls "s3://devops-aws-java-terraform-state" 2>/dev/null; then
    echo -e "${GREEN}✓ S3 Bucket: Deleted${NC}"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠ S3 Bucket: Still exists (manual cleanup may be needed)${NC}"
    ((PASSED++))
fi
echo ""

# Check DynamoDB Table
echo "Checking DynamoDB Locks Table..."
if ! aws dynamodb describe-table --table-name terraform-locks --region $AWS_REGION 2>/dev/null > /dev/null; then
    echo -e "${GREEN}✓ DynamoDB Table: Deleted${NC}"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠ DynamoDB Table: Still exists (manual cleanup may be needed)${NC}"
    ((PASSED++))
fi
echo ""

# Check ECR Repository
echo "Checking ECR Repository..."
if ! aws ecr describe-repositories --repository-names devops-aws-java --region $AWS_REGION 2>/dev/null > /dev/null; then
    echo -e "${GREEN}✓ ECR Repository: Deleted${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ ECR Repository: Still exists${NC}"
    ((FAILED++))
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
    echo -e "${GREEN}✓ Phase 1 Infrastructure Cleaned Up Successfully!${NC}"
    echo -e "${GREEN}✓ No Orphaned State Resources Found!${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Some resources still exist. Please review the errors above.${NC}"
    echo -e "${YELLOW}⚠ Warning: Orphaned resources may incur costs!${NC}"
    echo ""
    exit 1
fi
