# EKS Cluster Deployment Guide

## Overview
This Terraform configuration creates a production-ready EKS cluster with:
- **Public subnets** for ALB (Application Load Balancer) - accessible from internet
- **Private subnets** for EKS worker nodes - no direct internet access
- **NAT Gateways** for outbound traffic from private subnets
- **Private EKS endpoint** - cluster API only accessible from within VPC

## Architecture

```
Internet
   ↓
ALB (Public Subnets) ← Your IP via Security Group
   ↓
Service (Private Subnets)
   ↓
EKS Nodes (Private Subnets)
   ↓
NAT Gateway → Internet (for image pulls, etc.)
```

## What Will Be Created

### Networking (VPC)
- **VPC**: 10.0.0.0/16 CIDR block
- **Public Subnets**: 2 subnets (10.0.0.0/20, 10.0.1.0/20) across 2 AZs
  - Used for ALB only
  - Internet-facing
- **Private Subnets**: 2 subnets (10.0.2.0/20, 10.0.3.0/20) across 2 AZs
  - Used for EKS nodes
  - No direct internet access
- **Internet Gateway**: For public subnet internet access
- **NAT Gateways**: 2 NAT gateways for private subnet outbound traffic
- **Elastic IPs**: 2 EIPs for NAT gateways
- **Route Tables**: Public and private route tables with proper routing

### EKS Cluster
- **Cluster Name**: `devops-aws-java-cluster`
- **Kubernetes Version**: 1.29
- **Cluster Role**: IAM role with EKS cluster permissions
- **Endpoint Access**: Private only (no public access)
  - Cluster API only accessible from within VPC
  - Requires VPN/bastion for kubectl access

### Worker Nodes
- **Node Group**: 1 node group with auto-scaling
- **Instance Type**: t3.medium (2 vCPU, 4GB RAM)
- **Desired Size**: 2 nodes
- **Min Size**: 1 node
- **Max Size**: 4 nodes
- **Node Role**: IAM role with worker node permissions

## Cost Estimation

### Monthly Costs (Approximate)
- **EKS Cluster**: $73.00 (fixed)
- **EC2 Instances** (2x t3.medium): ~$60/month
- **NAT Gateways** (2x): ~$32/month
- **Elastic IPs**: ~$3.60/month
- **Data Transfer**: ~$5-10/month

**Total**: ~$170-180/month

## Deployment Steps

### 1. Review the Plan
```bash
terraform -chdir=terraform plan -out=eks-plan
```

### 2. Apply the Configuration
```bash
terraform -chdir=terraform apply eks-plan
```

**Estimated time**: 15-20 minutes

### 3. Configure kubectl (requires VPN/bastion)
```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name devops-aws-java-cluster
```

### 4. Verify Cluster
```bash
kubectl get nodes
kubectl get pods -A
```

## Deploy Microservice

### Dev Environment
```bash
helm install microservice helm/microservice \
  -f helm/microservice/values-dev.yaml \
  -n default
```

### Prod Environment
```bash
helm install microservice helm/microservice \
  -f helm/microservice/values-prod.yaml \
  -n default
```

### Get LoadBalancer URL
```bash
kubectl get svc microservice -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

## Cleanup

### Destroy Everything
```bash
terraform -chdir=terraform destroy
```

### Destroy Only EKS (Keep ECR)
```bash
terraform -chdir=terraform destroy -target=aws_eks_cluster.main -target=aws_eks_node_group.main
```
