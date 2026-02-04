# Java Microservice DevOps Pipeline - Complete Deployment Guide

## Project Overview

This project implements a production-grade CI/CD pipeline for a Spring Boot microservice on AWS with:
- **Spring Boot 3.x** microservice with health checks and metrics
- **Docker** multi-stage containerization (250MB optimized image)
- **GitHub Actions** pipeline (build, test, push to ECR, smoke tests)
- **AWS ECR** for container registry with image scanning
- **EKS** Kubernetes cluster for orchestration
- **Helm** for deployment templating and versioning
- **Terraform** for infrastructure as code

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Your Computer                           │
│                   (via Security Group)                      │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
        ┌────────────────────────────────┐
        │   AWS ALB (Public Subnets)     │
        │  devops-aws-java-alb-sg        │
        └────────────────┬───────────────┘
                         │
                         ▼
        ┌────────────────────────────────┐
        │  Kubernetes Service            │
        │  (LoadBalancer Type)           │
        └────────────────┬───────────────┘
                         │
                         ▼
        ┌────────────────────────────────┐
        │  EKS Cluster (Private Subnets) │
        │  - 2-4 Worker Nodes            │
        │  - Auto-scaling enabled        │
        └────────────────┬───────────────┘
                         │
                         ▼
        ┌────────────────────────────────┐
        │  Microservice Pods             │
        │  - Health checks               │
        │  - Metrics endpoint            │
        │  - Auto-scaling (HPA)          │
        └────────────────────────────────┘
```

## Prerequisites

### Local Machine
- AWS CLI configured with credentials
- Terraform >= 1.0
- kubectl
- Helm 3.x
- Docker (for local testing)
- Git

### AWS Account
- Account ID: `YOUR_AWS_ACCOUNT_ID`
- Region: `us-east-1`
- Security Group created: `devops-aws-java-alb-sg` (with your IP on port 80)

### GitHub Actions OIDC Provider (Required for CI/CD)

Before running GitHub Actions workflows, create the OIDC provider in your AWS account:

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
  --region us-east-1
```

This is a one-time setup that allows GitHub Actions to authenticate to AWS without storing long-lived credentials.

### GitHub
- Repository: `fhermq/devops-aws-java`
- GitHub Actions enabled
- GitHub Secret: `AWS_ACCOUNT_ID` set to your AWS account ID

## Deployment Phases

### Phase 1: Infrastructure Setup (Terraform)

#### Step 1: Initialize Terraform
```bash
terraform -chdir=terraform init
```

#### Step 2: Review the Plan
```bash
terraform -chdir=terraform plan -out=tfplan
```

This will create:
- VPC with public and private subnets
- EKS cluster (Kubernetes 1.29)
- Worker nodes (t3.medium, 2-4 auto-scaling)
- ECR repository (already created)
- IAM roles and security groups

#### Step 3: Apply Infrastructure
```bash
terraform -chdir=terraform apply tfplan
```

**Estimated time**: 15-20 minutes

#### Step 4: Configure kubectl
```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name devops-aws-java-cluster
```

#### Step 5: Verify Cluster
```bash
kubectl get nodes
kubectl get pods -A
```

### Phase 2: Deploy Microservice (Helm)

#### Option A: Development Environment
```bash
helm install microservice helm/microservice \
  -f helm/microservice/values-dev.yaml \
  -n default
```

**Configuration:**
- 1 replica
- No auto-scaling
- Minimal resources (50m CPU, 128Mi memory)

#### Option B: Production Environment
```bash
helm install microservice helm/microservice \
  -f helm/microservice/values-prod.yaml \
  -n default
```

**Configuration:**
- 3 replicas
- Auto-scaling 3-10 pods
- Higher resources (250m CPU, 256Mi memory)
- Pod anti-affinity (spread across nodes)

### Phase 3: Verify Deployment

#### Get LoadBalancer URL
```bash
kubectl get svc microservice -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

#### Test Endpoints
```bash
# Health check
curl http://<ALB-URL>/health

# Ready check
curl http://<ALB-URL>/ready

# API endpoint
curl http://<ALB-URL>/api/hello

# Metrics
curl http://<ALB-URL>/actuator/prometheus
```

#### Monitor Pods
```bash
# Watch pod status
kubectl get pods -w

# View pod logs
kubectl logs -f deployment/microservice

# Describe deployment
kubectl describe deployment microservice
```

## CI/CD Pipeline (GitHub Actions)

### Trigger Events
- Push to `main` branch
- Git tags (v*)
- Pull requests (validation only)
- Manual dispatch

### Pipeline Stages

#### 1. Build & Test
- Checkout code
- Setup Java 21
- Maven build and tests
- Upload test results

#### 2. Build Docker Image
- Multi-stage build
- Semantic versioning from git tags
- Optimize for size (250MB)

#### 3. Push to ECR
- OIDC authentication (no credentials!)
- Push to `YOUR_AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/devops-aws-java`
- ECR scanning enabled

#### 4. Smoke Tests
- Pull image from ECR
- Run container locally
- Test all endpoints
- Verify health checks

### Deployment Workflow

```
Git Push/Tag
    ↓
GitHub Actions Triggered
    ↓
Build & Test (Maven)
    ↓
Build Docker Image
    ↓
Push to ECR
    ↓
Smoke Tests
    ↓
✓ Ready for Kubernetes Deployment
```

## Manual Deployment to EKS

If you want to deploy without GitHub Actions:

```bash
# 1. Build Docker image locally
docker build -t devops-aws-java:v1.0.0 .

# 2. Tag for ECR
docker tag devops-aws-java:v1.0.0 \
  YOUR_AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/devops-aws-java:v1.0.0

# 3. Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  YOUR_AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# 4. Push to ECR
docker push YOUR_AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/devops-aws-java:v1.0.0

# 5. Update Helm values
# Edit helm/microservice/values.yaml and set:
# image.tag: v1.0.0

# 6. Deploy to EKS
helm upgrade --install microservice helm/microservice \
  -f helm/microservice/values-prod.yaml
```

## Monitoring & Troubleshooting

### View Logs
```bash
# Pod logs
kubectl logs -f deployment/microservice

# Previous pod logs (if crashed)
kubectl logs -p deployment/microservice

# All pods in namespace
kubectl logs -f -l app.kubernetes.io/name=microservice
```

### Check Pod Status
```bash
# Describe pod
kubectl describe pod <pod-name>

# Check events
kubectl get events --sort-by='.lastTimestamp'

# Check resource usage
kubectl top pods
kubectl top nodes
```

### Scale Deployment
```bash
# Manual scaling
kubectl scale deployment microservice --replicas=5

# Check HPA status
kubectl get hpa
kubectl describe hpa microservice
```

### Update Deployment
```bash
# Update image
kubectl set image deployment/microservice \
  microservice=YOUR_AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/devops-aws-java:v1.1.0

# Rollback to previous version
kubectl rollout undo deployment/microservice

# Check rollout history
kubectl rollout history deployment/microservice
```

## Cleanup

### Remove Microservice (Keep Cluster)
```bash
helm uninstall microservice
```

### Destroy EKS Cluster (Keep ECR)
```bash
terraform -chdir=terraform destroy -target=aws_eks_cluster.main -target=aws_eks_node_group.main
```

### Destroy Everything
```bash
terraform -chdir=terraform destroy
```

**Warning**: This will delete the entire cluster and all resources.

## Cost Management

### Estimated Monthly Costs
- EKS Cluster: $73
- EC2 Instances (2x t3.medium): $60
- NAT Gateways (2x): $32
- Elastic IPs: $3.60
- Data Transfer: $5-10

**Total**: ~$170-180/month

### Cost Optimization
1. **Scale down during off-hours**
   ```bash
   kubectl scale deployment microservice --replicas=1
   ```

2. **Use Spot instances** (saves ~70%)
   - Edit `terraform/eks.tf` and add `capacity_type = "SPOT"`

3. **Monitor resource usage**
   ```bash
   kubectl top pods
   kubectl top nodes
   ```

4. **Set resource requests/limits**
   - Already configured in `helm/microservice/values.yaml`

## Security Best Practices

### Implemented
- ✓ OIDC authentication (no long-lived credentials)
- ✓ Private EKS endpoint (not exposed to internet)
- ✓ Private subnets for worker nodes
- ✓ NAT gateway for outbound traffic
- ✓ ECR image scanning enabled
- ✓ Security group restricts ALB to your IP
- ✓ Non-root user in Docker image
- ✓ Resource limits defined

### Recommended Additions
- Network policies for pod-level security
- Pod security policies
- RBAC for kubectl access
- Secrets management (AWS Secrets Manager)
- Backup and disaster recovery
- GitOps (ArgoCD)

## Project Structure

```
.
├── src/                          # Spring Boot source code
│   ├── main/java/com/microservice/
│   │   ├── MicroserviceApplication.java
│   │   └── controller/
│   │       ├── HealthController.java
│   │       └── HelloController.java
│   └── test/java/com/microservice/
│       └── controller/
│           ├── HealthControllerTest.java
│           └── HelloControllerTest.java
├── pom.xml                       # Maven configuration
├── Dockerfile                    # Multi-stage Docker build
├── .dockerignore                 # Docker build optimization
├── .github/workflows/
│   └── deploy.yml               # GitHub Actions pipeline
├── terraform/                    # Infrastructure as Code
│   ├── main.tf                  # Terraform main config
│   ├── variables.tf             # Variables
│   ├── vpc.tf                   # VPC and networking
│   ├── eks.tf                   # EKS cluster
│   ├── ecr.tf                   # ECR repository
│   ├── iam.tf                   # IAM roles
│   ├── terraform.tfvars         # Terraform values
│   └── EKS_DEPLOYMENT_GUIDE.md  # EKS-specific guide
├── helm/microservice/            # Helm chart
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── values-dev.yaml
│   ├── values-prod.yaml
│   └── templates/
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── hpa.yaml
│       └── _helpers.tpl
└── DEPLOYMENT_GUIDE.md          # This file
```

## Quick Start (TL;DR)

```bash
# 1. Setup infrastructure
terraform -chdir=terraform init
terraform -chdir=terraform plan -out=tfplan
terraform -chdir=terraform apply tfplan

# 2. Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name devops-aws-java-cluster

# 3. Deploy microservice
helm install microservice helm/microservice -f helm/microservice/values-prod.yaml

# 4. Get URL
kubectl get svc microservice -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# 5. Test
curl http://<ALB-URL>/health
```

## Support & Troubleshooting

### Common Issues

**Nodes not joining cluster**
```bash
kubectl describe nodes
kubectl logs -n kube-system -l k8s-app=aws-node
```

**LoadBalancer not getting IP**
```bash
kubectl describe svc microservice
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

**Pod not starting**
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

**Image pull errors**
```bash
# Verify ECR credentials
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Check image exists
aws ecr describe-images --repository-name devops-aws-java --region us-east-1
```

## Next Steps

1. Deploy the infrastructure (Phase 1)
2. Deploy the microservice (Phase 2)
3. Test endpoints (Phase 3)
4. Configure monitoring (CloudWatch/Prometheus)
5. Set up auto-scaling policies
6. Implement GitOps (ArgoCD)
7. Add backup and disaster recovery

## References

- [Spring Boot Documentation](https://spring.io/projects/spring-boot)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Helm Documentation](https://helm.sh/docs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
