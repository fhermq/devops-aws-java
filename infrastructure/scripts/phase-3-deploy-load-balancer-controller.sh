#!/bin/bash

# Phase 3: Deploy AWS Load Balancer Controller (Official AWS Method)
# This script deploys the Load Balancer Controller using the official AWS Helm chart
# Usage: ./scripts/phase-3-deploy-load-balancer-controller.sh

set -e

echo ""
echo "=========================================="
echo "Phase 3: Deploy Load Balancer Controller"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
CLUSTER_NAME="devops-aws-java-cluster"
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "Cluster: $CLUSTER_NAME"
echo "Region: $AWS_REGION"
echo "Account: $AWS_ACCOUNT_ID"
echo ""

# Step 1: Create IAM policy
echo -e "${YELLOW}Step 1: Creating IAM policy...${NC}"
if aws iam get-policy --policy-arn arn:aws:iam::$AWS_ACCOUNT_ID:policy/AWSLoadBalancerControllerIAMPolicy &>/dev/null; then
    echo -e "${GREEN}✓ IAM policy already exists${NC}"
else
    echo "Downloading IAM policy..."
    curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.14.1/docs/install/iam_policy.json
    
    echo "Creating IAM policy..."
    aws iam create-policy \
        --policy-name AWSLoadBalancerControllerIAMPolicy \
        --policy-document file://iam_policy.json
    
    echo -e "${GREEN}✓ IAM policy created${NC}"
    rm iam_policy.json
fi
echo ""

# Step 2: Get OIDC provider
echo -e "${YELLOW}Step 2: Setting up IRSA (IAM Roles for Service Accounts)...${NC}"
OIDC_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --query 'cluster.identity.oidc.issuer' --output text | cut -d'/' -f5)
echo "OIDC ID: $OIDC_ID"

# Check if OIDC provider exists
if aws iam list-open-id-connect-providers --query "OpenIDConnectProviderList[*].Arn" --output text | grep -q $OIDC_ID; then
    echo -e "${GREEN}✓ OIDC provider exists${NC}"
else
    echo -e "${RED}✗ OIDC provider not found${NC}"
    echo "Creating OIDC provider..."
    eksctl utils associate-iam-oidc-provider --cluster=$CLUSTER_NAME --region=$AWS_REGION --approve
    echo -e "${GREEN}✓ OIDC provider created${NC}"
fi
echo ""

# Step 3: Create IAM role with trust relationship
echo -e "${YELLOW}Step 3: Creating IAM role with trust relationship...${NC}"
ROLE_NAME="AmazonEKSLoadBalancerControllerRole"

if aws iam get-role --role-name $ROLE_NAME &>/dev/null; then
    echo -e "${GREEN}✓ IAM role already exists${NC}"
    
    # Update trust relationship to include this cluster's OIDC provider
    echo "Updating trust relationship..."
    TRUST_POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::$AWS_ACCOUNT_ID:oidc-provider/oidc.eks.$AWS_REGION.amazonaws.com/id/$OIDC_ID"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.$AWS_REGION.amazonaws.com/id/$OIDC_ID:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller",
          "oidc.eks.$AWS_REGION.amazonaws.com/id/$OIDC_ID:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
EOF
)
    
    aws iam update-assume-role-policy \
        --role-name $ROLE_NAME \
        --policy-document "$TRUST_POLICY"
    
    echo -e "${GREEN}✓ Trust relationship updated${NC}"
else
    echo "Creating IAM role..."
    TRUST_POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::$AWS_ACCOUNT_ID:oidc-provider/oidc.eks.$AWS_REGION.amazonaws.com/id/$OIDC_ID"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.$AWS_REGION.amazonaws.com/id/$OIDC_ID:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller",
          "oidc.eks.$AWS_REGION.amazonaws.com/id/$OIDC_ID:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
EOF
)
    
    aws iam create-role \
        --role-name $ROLE_NAME \
        --assume-role-policy-document "$TRUST_POLICY"
    
    echo -e "${GREEN}✓ IAM role created${NC}"
fi
echo ""

# Step 4: Attach policy to role
echo -e "${YELLOW}Step 4: Attaching policy to role...${NC}"
aws iam attach-role-policy \
    --role-name $ROLE_NAME \
    --policy-arn arn:aws:iam::$AWS_ACCOUNT_ID:policy/AWSLoadBalancerControllerIAMPolicy
echo -e "${GREEN}✓ Policy attached${NC}"
echo ""

# Step 5: Create service account with IRSA annotation
echo -e "${YELLOW}Step 5: Creating Kubernetes service account with IRSA annotation...${NC}"
kubectl delete serviceaccount -n kube-system aws-load-balancer-controller --ignore-not-found=true
sleep 2

kubectl create serviceaccount -n kube-system aws-load-balancer-controller

kubectl annotate serviceaccount -n kube-system aws-load-balancer-controller \
    eks.amazonaws.com/role-arn=arn:aws:iam::$AWS_ACCOUNT_ID:role/$ROLE_NAME \
    --overwrite

echo -e "${GREEN}✓ Service account created with IRSA annotation${NC}"
echo ""

# Step 6: Add AWS Helm chart repository
echo -e "${YELLOW}Step 6: Adding AWS Helm chart repository...${NC}"
helm repo add eks https://aws.github.io/eks-charts
helm repo update eks
echo -e "${GREEN}✓ Helm repository updated${NC}"
echo ""

# Step 7: Install Load Balancer Controller using official AWS chart
echo -e "${YELLOW}Step 7: Installing AWS Load Balancer Controller...${NC}"

# Get VPC ID
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=cidr,Values=10.0.0.0/16" --query 'Vpcs[0].VpcId' --output text)
echo "VPC ID: $VPC_ID"

helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
    -n kube-system \
    --set clusterName=$CLUSTER_NAME \
    --set serviceAccount.create=false \
    --set serviceAccount.name=aws-load-balancer-controller \
    --set vpcId=$VPC_ID \
    --set region=$AWS_REGION \
    --timeout 10m

echo -e "${GREEN}✓ Load Balancer Controller installed${NC}"
echo ""

# Step 8: Verify deployment
echo -e "${YELLOW}Step 8: Verifying deployment...${NC}"
sleep 10

READY=$(kubectl get deployment -n kube-system aws-load-balancer-controller -o jsonpath='{.status.readyReplicas}')
DESIRED=$(kubectl get deployment -n kube-system aws-load-balancer-controller -o jsonpath='{.spec.replicas}')

if [ "$READY" == "$DESIRED" ]; then
    echo -e "${GREEN}✓ Load Balancer Controller is running ($READY/$DESIRED replicas)${NC}"
else
    echo -e "${YELLOW}⚠ Load Balancer Controller pods not ready yet ($READY/$DESIRED replicas)${NC}"
    echo "Waiting for pods to be ready..."
    kubectl rollout status deployment/aws-load-balancer-controller -n kube-system --timeout=5m || true
fi
echo ""

# Step 9: Check pod logs
echo -e "${YELLOW}Step 9: Checking pod logs...${NC}"
PODS=$(kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller -o jsonpath='{.items[*].metadata.name}')
for POD in $PODS; do
    echo -e "${YELLOW}Pod: $POD${NC}"
    kubectl logs -n kube-system $POD --tail=20 | head -20
    echo ""
done

echo -e "${GREEN}=========================================="
echo "✓ Load Balancer Controller Deployment Complete"
echo "==========================================${NC}"
echo ""
echo "Next steps:"
echo "1. Deploy a test service with type: LoadBalancer"
echo "2. Verify NLB is created in AWS"
echo "3. Test connectivity to the service"
echo ""
