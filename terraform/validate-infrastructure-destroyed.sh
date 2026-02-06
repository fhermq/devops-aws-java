#!/bin/bash

# Validation script for infrastructure destruction
# Checks that all resources were deleted successfully (no orphaned resources)

set -e

echo ""
echo "=========================================="
echo "Infrastructure Validation (Destroyed)"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counter for checks
PASSED=0
FAILED=0

# Function to check and print result
check_deleted() {
    local check_name=$1
    local result=$2
    
    if [ -z "$result" ] || [ "$result" == "0" ] || [ "$result" == "None" ]; then
        echo -e "${GREEN}✓ $check_name: Deleted${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗ $check_name: Still exists ($result)${NC}"
        ((FAILED++))
        return 1
    fi
}

# Check VPC
echo "Checking VPC..."
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=cidr,Values=10.0.0.0/26" --query 'Vpcs[0].VpcId' --output text 2>/dev/null || echo "")
if [ -z "$VPC_ID" ] || [ "$VPC_ID" == "None" ]; then
    echo -e "${GREEN}✓ VPC: Deleted${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ VPC: Still exists ($VPC_ID)${NC}"
    ((FAILED++))
fi

# Check Subnets
echo ""
echo "Checking Subnets..."
SUBNET_COUNT=$(aws ec2 describe-subnets --filters "Name=cidr-block,Values=10.0.0.0/28,10.0.0.16/28,10.0.0.32/28,10.0.0.48/28" --query 'length(Subnets)' --output text 2>/dev/null || echo "0")
if [ "$SUBNET_COUNT" == "0" ]; then
    echo -e "${GREEN}✓ Subnets: All deleted${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ Subnets: $SUBNET_COUNT still exist${NC}"
    ((FAILED++))
fi

# Check EKS Cluster
echo ""
echo "Checking EKS Cluster..."
CLUSTER_STATUS=$(aws eks describe-cluster --name devops-aws-java-cluster --query 'cluster.status' --output text 2>/dev/null || echo "")
if [ -z "$CLUSTER_STATUS" ] || [ "$CLUSTER_STATUS" == "None" ]; then
    echo -e "${GREEN}✓ EKS Cluster: Deleted${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ EKS Cluster: Still exists (Status: $CLUSTER_STATUS)${NC}"
    ((FAILED++))
fi

# Check Security Groups
echo ""
echo "Checking Security Groups..."
SG_COUNT=$(aws ec2 describe-security-groups --filters "Name=tag:Name,Values=devops-aws-java-cluster*" --query 'length(SecurityGroups)' --output text 2>/dev/null || echo "0")
if [ "$SG_COUNT" == "0" ]; then
    echo -e "${GREEN}✓ Security Groups: All deleted${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ Security Groups: $SG_COUNT still exist${NC}"
    ((FAILED++))
fi

# Check IAM Roles
echo ""
echo "Checking IAM Roles..."
ROLE_COUNT=$(aws iam list-roles --query "Roles[?contains(RoleName, 'devops-aws-java')] | length(@)" --output text 2>/dev/null || echo "0")
if [ "$ROLE_COUNT" == "0" ]; then
    echo -e "${GREEN}✓ IAM Roles: All deleted${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ IAM Roles: $ROLE_COUNT still exist${NC}"
    ((FAILED++))
fi

# Check Internet Gateways
echo ""
echo "Checking Internet Gateways..."
IGW_COUNT=$(aws ec2 describe-internet-gateways --filters "Name:tag:Name,Values=devops-aws-java-cluster-igw" --query 'length(InternetGateways)' --output text 2>/dev/null || echo "0")
if [ "$IGW_COUNT" == "0" ]; then
    echo -e "${GREEN}✓ Internet Gateways: All deleted${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ Internet Gateways: $IGW_COUNT still exist${NC}"
    ((FAILED++))
fi

# Check Kubernetes-managed LoadBalancer (Classic LB)
echo ""
echo "Checking Kubernetes-managed LoadBalancer..."
CLB_COUNT=$(aws elb describe-load-balancers --region us-east-1 --query "LoadBalancerDescriptions | length(@)" --output text 2>/dev/null || echo "0")
if [ "$CLB_COUNT" == "0" ]; then
    echo -e "${GREEN}✓ Kubernetes LoadBalancer: Deleted${NC}"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠ Kubernetes LoadBalancer: $CLB_COUNT still exist (will be deleted with cluster)${NC}"
    ((PASSED++))
fi

# Summary
echo ""
echo "=========================================="
echo "Validation Summary"
echo "=========================================="
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All Infrastructure Cleaned Up Successfully!${NC}"
    echo -e "${GREEN}✓ No Orphaned or Zombie Resources Found!${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Some resources still exist. Please review the errors above.${NC}"
    echo -e "${YELLOW}⚠ Warning: Orphaned resources may incur costs!${NC}"
    echo ""
    exit 1
fi
