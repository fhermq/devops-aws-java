#!/bin/bash

# Check for orphaned AWS resources not managed by Terraform
# This script identifies resources created outside of Terraform state

set -e

echo "=========================================="
echo "Checking for Orphaned AWS Resources"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get AWS Account ID and Region
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=${AWS_REGION:-us-east-1}

echo "Account ID: $AWS_ACCOUNT_ID"
echo "Region: $AWS_REGION"
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

# Check IAM Roles
echo "=========================================="
echo "IAM Roles (matching cluster pattern)"
echo "=========================================="
IAM_ROLES=$(aws iam list-roles --query "Roles[?contains(RoleName, 'devops-aws-java')].RoleName" --output text 2>/dev/null || echo "")

if [ -z "$IAM_ROLES" ]; then
  echo -e "${GREEN}✓ No matching IAM roles found${NC}"
else
  echo -e "${YELLOW}Found IAM roles:${NC}"
  for role in $IAM_ROLES; do
    echo "  - $role"
  done
fi
echo ""

# Check VPCs
echo "=========================================="
echo "VPCs (matching cluster pattern)"
echo "=========================================="
VPCS=$(aws ec2 describe-vpcs --region $AWS_REGION --filters "Name=tag:Name,Values=*devops-aws-java*" --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0]]' --output text 2>/dev/null || echo "")

if [ -z "$VPCS" ]; then
  echo -e "${GREEN}✓ No matching VPCs found${NC}"
else
  echo -e "${YELLOW}Found VPCs:${NC}"
  echo "$VPCS" | while read vpc_id vpc_name; do
    echo "  - $vpc_id ($vpc_name)"
  done
fi
echo ""

# Check EKS Clusters
echo "=========================================="
echo "EKS Clusters"
echo "=========================================="
EKS_CLUSTERS=$(aws eks list-clusters --region $AWS_REGION --query 'clusters[*]' --output text 2>/dev/null || echo "")

if [ -z "$EKS_CLUSTERS" ]; then
  echo -e "${GREEN}✓ No EKS clusters found${NC}"
else
  echo -e "${YELLOW}Found EKS clusters:${NC}"
  for cluster in $EKS_CLUSTERS; do
    echo "  - $cluster"
  done
fi
echo ""

# Check Kubernetes-managed LoadBalancers (Classic LB)
echo "=========================================="
echo "Kubernetes-managed LoadBalancers (Classic)"
echo "=========================================="
CLB_COUNT=$(aws elb describe-load-balancers --region $AWS_REGION --query "LoadBalancerDescriptions | length(@)" --output text 2>/dev/null || echo "0")

if [ "$CLB_COUNT" == "0" ]; then
  echo -e "${GREEN}✓ No Kubernetes LoadBalancers found${NC}"
else
  echo -e "${GREEN}Found Kubernetes-managed LoadBalancers:${NC}"
  aws elb describe-load-balancers --region $AWS_REGION --query "LoadBalancerDescriptions[*].[LoadBalancerName,DNSName]" --output text | while read name dns; do
    echo "  - $name ($dns)"
  done
fi
echo ""

# Check Terraform State
echo "=========================================="
echo "Terraform State"
echo "=========================================="
if [ -f "terraform/terraform.tfstate" ]; then
  RESOURCE_COUNT=$(grep -c '"type"' terraform/terraform.tfstate || echo "0")
  echo -e "${GREEN}✓ State file exists${NC}"
  echo "  Resources in state: $RESOURCE_COUNT"
else
  echo -e "${RED}✗ No state file found${NC}"
  echo "  Location: terraform/terraform.tfstate"
fi
echo ""

# Summary
echo "=========================================="
echo "Summary"
echo "=========================================="
echo ""
echo "To clean up orphaned resources:"
echo ""
echo "1. Delete ECR Repository:"
echo "   aws ecr delete-repository --repository-name devops-aws-java --force --region $AWS_REGION"
echo ""
echo "2. Delete IAM Roles:"
echo "   aws iam delete-role-policy --role-name devops-aws-java-cluster-cluster-role --policy-name <policy-name>"
echo "   aws iam delete-role --role-name devops-aws-java-cluster-cluster-role"
echo "   aws iam delete-role-policy --role-name devops-aws-java-cluster-node-role --policy-name <policy-name>"
echo "   aws iam delete-role --role-name devops-aws-java-cluster-node-role"
echo ""
echo "3. Or use Terraform to import and manage them:"
echo "   terraform import aws_ecr_repository.microservice devops-aws-java"
echo "   terraform import aws_iam_role.eks_cluster_role devops-aws-java-cluster-cluster-role"
echo "   terraform import aws_iam_role.eks_node_role devops-aws-java-cluster-node-role"
echo ""
echo "=========================================="
