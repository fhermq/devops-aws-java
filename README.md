# Java Microservice DevOps Pipeline

A production-grade CI/CD pipeline for Spring Boot microservices on AWS with Kubernetes, Helm, and Terraform.

## 🚀 Quick Start

**First time setup?** Start here: [SETUP.md](SETUP.md)

```bash
# 1. Clone and configure
git clone https://github.com/fhermq/devops-aws-java.git
cd devops-aws-java
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform/terraform.tfvars with your AWS account ID and GitHub org

# 2. Deploy infrastructure
terraform -chdir=terraform init
terraform -chdir=terraform apply -auto-approve

# 3. Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name devops-aws-java-cluster

# 4. Deploy microservice
helm install microservice helm/microservice -f helm/microservice/values-prod.yaml

# 5. Get LoadBalancer URL
kubectl get svc microservice -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for detailed instructions.

## 📚 Documentation

- **[SETUP.md](SETUP.md)** - Initial setup and configuration (AWS, GitHub, credentials)
- **[SECURITY.md](SECURITY.md)** - Security best practices and pre-commit checklist
- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Complete deployment instructions
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - How to contribute to this project
- **[E2E_TEST_PLAN.md](E2E_TEST_PLAN.md)** - End-to-end testing procedures
- **[CI_CD_WORKFLOW_SUMMARY.md](CI_CD_WORKFLOW_SUMMARY.md)** - GitHub Actions pipeline details
- **[terraform/EKS_DEPLOYMENT_GUIDE.md](terraform/EKS_DEPLOYMENT_GUIDE.md)** - EKS-specific deployment guide

## 📋 Features

### Application
- **Spring Boot 3.x** microservice
- Health checks (`/health`, `/ready`)
- Prometheus metrics (`/actuator/prometheus`)
- Sample API endpoint (`/api/hello`)
- Full unit test coverage

### Containerization
- Multi-stage Docker build
- Optimized image size (250MB)
- Non-root user for security
- Health check configured

### CI/CD Pipeline
- GitHub Actions workflow
- Maven build and testing
- Docker image build and push
- ECR image scanning
- Smoke tests post-deployment
- OIDC authentication (no credentials!)

### Infrastructure
- AWS EKS cluster (Kubernetes 1.29)
- VPC with public/private subnets
- NAT gateways for secure outbound traffic
- Auto-scaling worker nodes (1-4)
- ECR repository with lifecycle policies

### Deployment
- Helm charts for templating
- Environment-specific values (dev/prod)
- Horizontal Pod Autoscaler (HPA)
- LoadBalancer service with security group
- Liveness and readiness probes

## 📁 Project Structure

```
.
├── src/                          # Spring Boot application
├── pom.xml                       # Maven configuration
├── Dockerfile                    # Multi-stage build
├── .github/workflows/deploy.yml  # GitHub Actions pipeline
├── terraform/                    # Infrastructure as Code
│   ├── main.tf, vpc.tf, eks.tf, ecr.tf, iam.tf
│   └── EKS_DEPLOYMENT_GUIDE.md
├── helm/microservice/            # Helm chart
│   ├── Chart.yaml, values.yaml
│   ├── values-dev.yaml, values-prod.yaml
│   └── templates/
├── DEPLOYMENT_GUIDE.md           # Complete deployment guide
└── README.md                     # This file
```

## 🔧 Prerequisites

- AWS Account (YOUR_AWS_ACCOUNT_ID)
- AWS CLI configured
- Terraform >= 1.0
- kubectl
- Helm 3.x
- Docker
- Git

## 📊 Architecture

```
Your Computer (via Security Group)
    ↓
AWS ALB (Public Subnets)
    ↓
Kubernetes Service (LoadBalancer)
    ↓
EKS Cluster (Private Subnets)
    ↓
Microservice Pods (Auto-scaling)
```

## 💰 Cost Estimation

- EKS Cluster: $73/month
- EC2 Instances (2x t3.medium): $60/month
- NAT Gateways: $32/month
- Other: ~$10/month

**Total**: ~$175/month

## 🔐 Security

- ✓ OIDC authentication (no long-lived credentials)
- ✓ Private EKS endpoint
- ✓ Private subnets for worker nodes
- ✓ Security group restricts ALB to your IP
- ✓ ECR image scanning
- ✓ Non-root Docker user
- ✓ Resource limits defined

## 📖 Documentation

- [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Complete deployment instructions
- [terraform/EKS_DEPLOYMENT_GUIDE.md](terraform/EKS_DEPLOYMENT_GUIDE.md) - EKS-specific guide
- [.kiro/specs/java-microservice-pipeline/](./kiro/specs/java-microservice-pipeline/) - Design and requirements

## 🧪 Testing

### Local Testing
```bash
# Build Docker image
docker build -t devops-aws-java:latest .

# Run container
docker run -p 8080:8080 devops-aws-java:latest

# Test endpoints
curl http://localhost:8080/health
curl http://localhost:8080/api/hello
```

### Unit Tests
```bash
mvn clean test
```

### Smoke Tests (Post-Deployment)
```bash
# Automatically run in GitHub Actions
# Or manually:
curl http://<ALB-URL>/health
curl http://<ALB-URL>/ready
curl http://<ALB-URL>/api/hello
curl http://<ALB-URL>/actuator/prometheus
```

## 🚢 Deployment

### Development
```bash
helm install microservice helm/microservice -f helm/microservice/values-dev.yaml
```

### Production
```bash
helm install microservice helm/microservice -f helm/microservice/values-prod.yaml
```

## 📈 Monitoring

### View Logs
```bash
kubectl logs -f deployment/microservice
```

### Check Pod Status
```bash
kubectl get pods
kubectl describe pod <pod-name>
```

### Monitor Resources
```bash
kubectl top pods
kubectl top nodes
```

## 🔄 CI/CD Pipeline

Triggered on:
- Push to `main` branch
- Git tags (v*)
- Pull requests (validation only)
- Manual dispatch

Pipeline stages:
1. Build & Test (Maven)
2. Build Docker Image
3. Push to ECR
4. Smoke Tests

## 🛠️ Troubleshooting

### Nodes not joining
```bash
kubectl describe nodes
kubectl logs -n kube-system -l k8s-app=aws-node
```

### LoadBalancer not getting IP
```bash
kubectl describe svc microservice
```

### Pod not starting
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for more troubleshooting.

## 📝 License

MIT

## 👤 Author

DevOps Team

## 🤝 Contributing

1. Create a feature branch
2. Make changes
3. Push to GitHub
4. Create Pull Request
5. GitHub Actions will validate

## 📞 Support

For issues or questions, refer to [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) or check the troubleshooting section.
