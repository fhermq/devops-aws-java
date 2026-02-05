#!/bin/bash

# Validation script for infrastructure creation
# Checks that all resources were created successfully

set -e

echo ""
echo "=========================================="
echo "Infrastructure Validation (Created)"
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
check_result() {
    local check_name=$1
    local result=$2
    
    if [ -z "$result" ] || [ "$result" == "0" ]; then
        echo -e "${RED}✗ $check_name: FAILED${NC}"
        ((FAILED++))
        return 1
    else
        echo -e "${GREEN}✓ $check_name: PASSED${NC}"
        ((PASSED++))
        return 0
    fi
}

# Get VPC ID
echo "Checking VPC..."
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=cidr,Values=10.0.0.0/26" --query 'Vpcs[0].VpcId' --output text 2>/dev/null || echo "")
if [ "$VPC_ID" != "None" ] && [ ! -z "$VPC_ID" ]; then
    echo -e "${GREEN}✓ VPC: $VPC_ID (10.0.0.0/26)${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ VPC: NOT FOUND${NC}"
    ((FAILED++))
    exit 1
fi

# Check subnets
echo ""
echo "Checking Subnets..."
SUBNET_COUNT=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'length(Subnets)' --output text 2>/dev/null || echo "0")
if [ "$SUBNET_COUNT" == "4" ]; then
    echo -e "${GREEN}✓ Subnets: $SUBNET_COUNT total (2 public, 2 private)${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ Subnets: Expected 4, found $SUBNET_COUNT${NC}"
    ((FAILED++))
fi

# Check NAT Gateways
echo ""
echo "Checking NAT Gateways..."
NAT_COUNT=$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" "Name=state,Values=available" --query 'length(NatGateways)' --output text 2>/dev/null || echo "0")
if [ "$NAT_COUNT" == "2" ]; then
    echo -e "${GREEN}✓ NAT Gateways: $NAT_COUNT available${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ NAT Gateways: Expected 2, found $NAT_COUNT${NC}"
    ((FAILED++))
fi

# Check EKS Cluster
echo ""
echo "Checking EKS Cluster..."
CLUSTER_STATUS=$(aws eks describe-cluster --name devops-aws-java-cluster --query 'cluster.status' --output text 2>/dev/null || echo "")
if [ "$CLUSTER_STATUS" == "ACTIVE" ]; then
    echo -e "${GREEN}✓ EKS Cluster: ACTIVE${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ EKS Cluster: Status is $CLUSTER_STATUS (expected ACTIVE)${NC}"
    ((FAILED++))
fi

# Check Worker Nodes (via EC2 instances)
echo ""
echo "Checking Worker Nodes..."
NODE_COUNT=$(aws ec2 describe-instances --filters "Name=tag:eks:nodegroup-name,Values=devops-aws-java-cluster-node-group" "Name=instance-state-name,Values=running" --query 'length(Reservations[*].Instances[*])' --output text 2>/dev/null || echo "0")
if [ "$NODE_COUNT" -ge "2" ]; then
    echo -e "${GREEN}✓ Worker Nodes: $NODE_COUNT running${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ Worker Nodes: Expected 2, found $NODE_COUNT${NC}"
    ((FAILED++))
fi

# Check Security Groups
echo ""
echo "Checking Security Groups..."
SG_COUNT=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" --query 'length(SecurityGroups)' --output text 2>/dev/null || echo "0")
if [ "$SG_COUNT" -ge "2" ]; then
    echo -e "${GREEN}✓ Security Groups: $SG_COUNT created${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ Security Groups: Expected at least 2, found $SG_COUNT${NC}"
    ((FAILED++))
fi

# Check IAM Roles
echo ""
echo "Checking IAM Roles..."
ROLE_COUNT=$(aws iam list-roles --query "Roles[?contains(RoleName, 'devops-aws-java')] | length(@)" --output text 2>/dev/null || echo "0")
if [ "$ROLE_COUNT" -ge "2" ]; then
    echo -e "${GREEN}✓ IAM Roles: $ROLE_COUNT created${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ IAM Roles: Expected at least 2, found $ROLE_COUNT${NC}"
    ((FAILED++))
fi

# Check Network Load Balancer
echo ""
echo "Checking Network Load Balancer..."
NLB_COUNT=$(aws elbv2 describe-load-balancers --region us-east-1 --query "LoadBalancers[?contains(LoadBalancerName, 'devops-aws-java-cluster-nlb')] | length(@)" --output text 2>/dev/null || echo "0")
if [ "$NLB_COUNT" -ge "1" ]; then
    echo -e "${YELLOW}⚠ Terraform-managed NLB found (deprecated - using Kubernetes LoadBalancer instead)${NC}"
    ((PASSED++))
else
    echo -e "${GREEN}✓ No Terraform-managed NLB (using Kubernetes LoadBalancer)${NC}"
    ((PASSED++))
fi

# Check Target Group
echo ""
echo "Checking Target Group..."
TG_COUNT=$(aws elbv2 describe-target-groups --region us-east-1 --query "TargetGroups[?contains(TargetGroupName, 'devops-aws-java-cluster-tg')] | length(@)" --output text 2>/dev/null || echo "0")
if [ "$TG_COUNT" -ge "1" ]; then
    echo -e "${YELLOW}⚠ Terraform-managed Target Group found (deprecated - using Kubernetes LoadBalancer instead)${NC}"
    ((PASSED++))
else
    echo -e "${GREEN}✓ No Terraform-managed Target Group (using Kubernetes LoadBalancer)${NC}"
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
    echo -e "${GREEN}✓ All Infrastructure Created Successfully!${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Some checks failed. Please review the errors above.${NC}"
    echo ""
    exit 1
fi
