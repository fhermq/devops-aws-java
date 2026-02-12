# Infrastructure as Code

Terraform configurations and Helm charts for deploying the Java microservice on AWS EKS.

## Structure

- `terraform/` - Infrastructure as Code using Terraform
  - `phase-1-backend/` - S3, DynamoDB, ECR, GitHub OIDC setup
  - `phase-2-eks/` - VPC, EKS cluster, worker nodes
  
- `helm/` - Kubernetes deployment templates
  - `microservice/` - Java microservice Helm chart
  - `nginx-test/` - Test deployment
  - `aws-load-balancer-controller/` - AWS Load Balancer Controller

- `scripts/` - Deployment and validation scripts

## Quick Start

See [terraform/README.md](terraform/README.md) for Terraform deployment instructions.

## Deployment

### Phase 1: Backend Infrastructure
```bash
./scripts/phase-1-setup-backend.sh
```

### Phase 2: EKS Cluster
```bash
cd terraform/phase-2-eks
terraform init
terraform plan
terraform apply
```

### Phase 3: Deploy Application
```bash
helm install microservice helm/microservice -f helm/microservice/values-prod.yaml
```
