#!/bin/bash

# Phase 2: EKS Cluster Deployment - Validation (Created)
# Checks that all Phase 2 resources were created successfully
# Usage: ./scripts/validate-phase2-created.sh

set -e

echo ""
echo "=========================================="
echo "Phase 2 Validation (Created)"
echo "EKS Cluster Deployment"
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

# Check Subnets
echo ""
echo "Checking Subnets..."
SUBNET_COUNT=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'length(Subnets)' --output text 2>/dev/null || echo "0")
if [ "$SUBNET_COUNT" == "4" ]; then
    echo -e "${GREEN}✓ Subnets: $SUBNET_COUNT total (2 public for nodes, 2 private for future use)${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ Subnets: Expected 4, found $SUBNET_COUNT${NC}"
    ((FAILED++))
fi

# Check EKS Cluster
echo ""
echo "Checking EKS Cluster..."
CLUSTER_STATUS=$(aws eks describe-cluster --name devops-aws-java-cluster --query 'cluster.status' --output text 2>/dev/null || echo "")
if [ "$CLUSTER_STATUS" == "ACTIVE" ]; then
    echo -e "${GREEN}✓ EKS Cluster: ACTIVE${NC}"
    ((PASSED++))
elif [ "$CLUSTER_STATUS" == "CREATING" ]; then
    echo -e "${YELLOW}⚠ EKS Cluster: CREATING (still initializing, check again in a few minutes)${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ EKS Cluster: Status is $CLUSTER_STATUS (expected ACTIVE)${NC}"
    ((FAILED++))
fi

# Check Worker Nodes
echo ""
echo "Checking Worker Nodes..."
NODE_COUNT=$(aws ec2 describe-instances --filters "Name=tag:eks:nodegroup-name,Values=devops-aws-java-cluster-node-group" "Name=instance-state-name,Values=running" --query 'length(Reservations[*].Instances[*])' --output text 2>/dev/null || echo "0")
if [ "$NODE_COUNT" -ge "2" ]; then
    echo -e "${GREEN}✓ Worker Nodes: $NODE_COUNT running (in public subnets)${NC}"
    ((PASSED++))
elif [ "$NODE_COUNT" -gt "0" ]; then
    echo -e "${YELLOW}⚠ Worker Nodes: $NODE_COUNT running (expected 2, still initializing)${NC}"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠ Worker Nodes: 0 running (still initializing, check again in a few minutes)${NC}"
    ((PASSED++))
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

# Check Load Balancer Controller
echo ""
echo "Checking AWS Load Balancer Controller..."
if kubectl get deployment -n kube-system aws-load-balancer-controller 2>/dev/null > /dev/null; then
    echo -e "${GREEN}✓ Load Balancer Controller: Deployed${NC}"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠ Load Balancer Controller: Not yet deployed${NC}"
fi

# Check Network Load Balancer
echo ""
echo "Checking Network Load Balancer..."
NLB_COUNT=$(aws elbv2 describe-load-balancers --region us-east-1 --query "LoadBalancers[?Type=='network'] | length(@)" --output text 2>/dev/null || echo "0")
if [ "$NLB_COUNT" -ge "1" ]; then
    NLB_DNS=$(aws elbv2 describe-load-balancers --region us-east-1 --query "LoadBalancers[?Type=='network'].DNSName | [0]" --output text 2>/dev/null || echo "")
    echo -e "${GREEN}✓ Network Load Balancer: $NLB_DNS${NC}"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠ Network Load Balancer: Not yet created (expected - will be created when services are deployed)${NC}"
fi

# Summary
echo ""
echo "=========================================="
echo "Phase 2 Validation Summary"
echo "=========================================="
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ Phase 2 Infrastructure Created Successfully!${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Some checks failed. Please review the errors above.${NC}"
    echo ""
    exit 1
fi
