#!/bin/bash

# Phase 2: EKS Cluster - Cleanup Orphaned Resources
# Safely deletes resources that are out of sync with Terraform state
# Usage: ./scripts/phase-2-cleanup-orphaned.sh

set -e

echo "=========================================="
echo "Cleaning Up Orphaned AWS Resources"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

AWS_REGION=${AWS_REGION:-us-east-1}

# Function to confirm action
confirm() {
    local prompt="$1"
    local response
    read -p "$(echo -e ${YELLOW}$prompt${NC})" response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

echo "This script will delete:"
echo "  - ECR repository: devops-aws-java"
echo "  - IAM roles: devops-aws-java-cluster-cluster-role, devops-aws-java-cluster-node-role"
echo "  - Associated policies"
echo ""
echo "Note: Kubernetes-managed NLB and Terraform-managed resources will be cleaned up automatically when the cluster is destroyed"
echo ""

if ! confirm "Continue? (yes/no): "; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "=========================================="
echo "Step 1: Delete ECR Repository"
echo "=========================================="
echo "Deleting ECR repository: devops-aws-java"
aws ecr delete-repository --repository-name devops-aws-java --force --region $AWS_REGION 2>/dev/null && \
    echo -e "${GREEN}✓ ECR repository deleted${NC}" || \
    echo -e "${YELLOW}⚠ ECR repository not found or already deleted${NC}"
echo ""

echo "=========================================="
echo "Step 2: Delete IAM Roles and Policies"
echo "=========================================="

# Function to delete role with all policies
delete_role_with_policies() {
    local role_name=$1
    
    echo "Processing role: $role_name"
    
    # Detach managed policies
    echo "  Detaching managed policies..."
    MANAGED_POLICIES=$(aws iam list-attached-role-policies --role-name "$role_name" --query 'AttachedPolicies[*].PolicyName' --output text 2>/dev/null || echo "")
    
    if [ ! -z "$MANAGED_POLICIES" ]; then
        for policy in $MANAGED_POLICIES; do
            echo "    - Detaching: $policy"
            aws iam detach-role-policy --role-name "$role_name" --policy-arn "arn:aws:iam::aws:policy/$policy" 2>/dev/null || true
        done
    fi
    
    # Delete inline policies
    echo "  Deleting inline policies..."
    INLINE_POLICIES=$(aws iam list-role-policies --role-name "$role_name" --query 'PolicyNames[*]' --output text 2>/dev/null || echo "")
    
    if [ ! -z "$INLINE_POLICIES" ]; then
        for policy in $INLINE_POLICIES; do
            echo "    - Deleting: $policy"
            aws iam delete-role-policy --role-name "$role_name" --policy-name "$policy" 2>/dev/null || true
        done
    fi
    
    # Delete the role
    echo "  Deleting role..."
    aws iam delete-role --role-name "$role_name" 2>/dev/null && \
        echo -e "${GREEN}✓ Role deleted: $role_name${NC}" || \
        echo -e "${RED}✗ Failed to delete role: $role_name${NC}"
}

delete_role_with_policies "devops-aws-java-cluster-cluster-role"
echo ""
delete_role_with_policies "devops-aws-java-cluster-node-role"
echo ""

echo "=========================================="
echo "Step 3: Delete Orphaned VPCs"
echo "=========================================="

# Get all VPCs matching the pattern
VPCS=$(aws ec2 describe-vpcs --region $AWS_REGION --filters "Name=tag:Name,Values=*devops-aws-java*" --query 'Vpcs[*].VpcId' --output text 2>/dev/null || echo "")

if [ -z "$VPCS" ]; then
    echo -e "${GREEN}✓ No orphaned VPCs found${NC}"
else
    echo "Found orphaned VPCs: $VPCS"
    for vpc_id in $VPCS; do
        echo ""
        echo "Cleaning up VPC: $vpc_id"
        
        # Delete NAT Gateways
        echo "  Deleting NAT Gateways..."
        NAT_GW_IDS=$(aws ec2 describe-nat-gateways --region $AWS_REGION --filter "Name=vpc-id,Values=$vpc_id" --query 'NatGateways[*].NatGatewayId' --output text 2>/dev/null || echo "")
        for nat_gw in $NAT_GW_IDS; do
            echo "    - Deleting NAT Gateway: $nat_gw"
            aws ec2 delete-nat-gateway --nat-gateway-id $nat_gw --region $AWS_REGION 2>/dev/null || true
        done
        
        # Wait for NAT Gateways to be deleted
        if [ ! -z "$NAT_GW_IDS" ]; then
            echo "    Waiting for NAT Gateways to be deleted..."
            sleep 10
        fi
        
        # Release Elastic IPs
        echo "  Releasing Elastic IPs..."
        EIP_IDS=$(aws ec2 describe-addresses --region $AWS_REGION --filters "Name=domain,Values=vpc" --query "Addresses[?AssociationId!=null].AllocationId" --output text 2>/dev/null || echo "")
        for eip in $EIP_IDS; do
            echo "    - Releasing EIP: $eip"
            aws ec2 release-address --allocation-id $eip --region $AWS_REGION 2>/dev/null || true
        done
        
        # Delete Internet Gateways
        echo "  Deleting Internet Gateways..."
        IGW_IDS=$(aws ec2 describe-internet-gateways --region $AWS_REGION --filters "Name=attachment.vpc-id,Values=$vpc_id" --query 'InternetGateways[*].InternetGatewayId' --output text 2>/dev/null || echo "")
        for igw in $IGW_IDS; do
            echo "    - Detaching IGW: $igw"
            aws ec2 detach-internet-gateway --internet-gateway-id $igw --vpc-id $vpc_id --region $AWS_REGION 2>/dev/null || true
            echo "    - Deleting IGW: $igw"
            aws ec2 delete-internet-gateway --internet-gateway-id $igw --region $AWS_REGION 2>/dev/null || true
        done
        
        # Delete Subnets
        echo "  Deleting Subnets..."
        SUBNET_IDS=$(aws ec2 describe-subnets --region $AWS_REGION --filters "Name=vpc-id,Values=$vpc_id" --query 'Subnets[*].SubnetId' --output text 2>/dev/null || echo "")
        for subnet in $SUBNET_IDS; do
            echo "    - Deleting Subnet: $subnet"
            aws ec2 delete-subnet --subnet-id $subnet --region $AWS_REGION 2>/dev/null || true
        done
        
        # Delete Route Tables
        echo "  Deleting Route Tables..."
        RT_IDS=$(aws ec2 describe-route-tables --region $AWS_REGION --filters "Name=vpc-id,Values=$vpc_id" "Name=association.main,Values=false" --query 'RouteTables[*].RouteTableId' --output text 2>/dev/null || echo "")
        for rt in $RT_IDS; do
            echo "    - Deleting Route Table: $rt"
            aws ec2 delete-route-table --route-table-id $rt --region $AWS_REGION 2>/dev/null || true
        done
        
        # Delete Security Groups (except default)
        echo "  Deleting Security Groups..."
        SG_IDS=$(aws ec2 describe-security-groups --region $AWS_REGION --filters "Name=vpc-id,Values=$vpc_id" "Name=group-name,Values=!default" --query 'SecurityGroups[*].GroupId' --output text 2>/dev/null || echo "")
        for sg in $SG_IDS; do
            echo "    - Deleting Security Group: $sg"
            aws ec2 delete-security-group --group-id $sg --region $AWS_REGION 2>/dev/null || true
        done
        
        # Delete VPC
        echo "  Deleting VPC: $vpc_id"
        aws ec2 delete-vpc --vpc-id $vpc_id --region $AWS_REGION 2>/dev/null && \
            echo -e "${GREEN}✓ VPC deleted: $vpc_id${NC}" || \
            echo -e "${RED}✗ Failed to delete VPC: $vpc_id${NC}"
    done
fi
echo ""

echo "=========================================="
echo "Step 4: Cleanup Summary"
echo "=========================================="
echo -e "${GREEN}✓ Orphaned resources cleaned up${NC}"
echo ""
echo "Next steps:"
echo "  1. Verify state file is clean: terraform state list"
echo "  2. Run Terraform apply: terraform -chdir=terraform apply"
echo ""
echo "=========================================="
