# Java Microservice DevOps Pipeline - Design

## Architecture Overview

```
┌─────────────┐
│ Git Push    │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────────────────────────────┐
│         GitHub Actions Workflow (deploy.yml)                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Checkout Code                                           │
│  2. Setup Java (Maven)                                      │
│  3. Build & Test (Maven)                                    │
│  4. Build Docker Image (Multi-stage)                        │
│  5. Authenticate to AWS (OIDC)                              │
│  6. Push to ECR                                             │
│  7. Deploy to EKS (Helm)                                    │
│  8. Run Smoke Tests                                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
       │
       ├─────────────────────┬──────────────────────┐
       ▼                     ▼                      ▼
   ┌────────┐          ┌──────────┐          ┌──────────┐
   │  ECR   │          │   EKS    │          │ Metrics  │
   │ (Image)│          │(Deployed)│          │  Logs    │
   └────────┘          └──────────┘          └──────────┘
```

## Component Design

### 1. Spring Boot Microservice
- **Framework**: Spring Boot 3.x
- **Endpoints**:
  - `GET /health` - Liveness probe
  - `GET /ready` - Readiness probe
  - `GET /metrics` - Prometheus metrics
  - `GET /api/hello` - Sample endpoint
- **Build Tool**: Maven with multi-module support
- **Testing**: JUnit 5 + Mockito

### 2. Docker Image Strategy
- **Multi-stage Build**:
  - Stage 1: Maven build (includes all dependencies)
  - Stage 2: Runtime (minimal JRE, only app jar)
- **Base Image**: `eclipse-temurin:21-jre-alpine` (small, secure)
- **Image Size Target**: < 200MB
- **Versioning**: `{registry}/{repo}:{git-tag}` or `{registry}/{repo}:latest`

### 3. GitHub Actions Workflow
- **Trigger Events**: 
  - Push to `main` branch
  - Pull requests (validation only, no deploy)
  - Manual trigger (workflow_dispatch)
- **Environment Variables**:
  - `AWS_REGION`: us-east-1
  - `ECR_REGISTRY`: {account-id}.dkr.ecr.us-east-1.amazonaws.com
  - `ECR_REPOSITORY`: microservice
  - `EKS_CLUSTER`: microservice-cluster
  - `EKS_NAMESPACE`: default
- **Secrets**: None (OIDC handles auth)

### 4. AWS Infrastructure (Terraform)
- **ECR Repository**:
  - Image scanning enabled
  - Lifecycle policy (keep last 10 images)
  - Encryption at rest
- **IAM Role** (for GitHub OIDC):
  - Trust relationship with GitHub
  - Permissions: ECR push/pull only
  - No S3, no EC2, no other services
- **EKS Cluster**: Pre-existing (assumed to exist)

### 5. Helm Chart Structure
```
helm/microservice/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Default values
├── values-dev.yaml         # Dev overrides
├── values-prod.yaml        # Prod overrides
└── templates/
    ├── deployment.yaml     # Kubernetes Deployment
    ├── service.yaml        # Kubernetes Service
    ├── configmap.yaml      # Configuration
    └── hpa.yaml            # Horizontal Pod Autoscaler (optional)
```

- **Deployment Configuration**:
  - Replicas: 2 (dev), 3 (prod)
  - Resource Limits: 256Mi memory, 250m CPU
  - Liveness Probe: `/health` every 10s
  - Readiness Probe: `/ready` every 5s
  - Image Pull Policy: IfNotPresent

### 6. Pipeline Stages

#### Stage 1: Build & Test
```yaml
- Checkout code
- Setup Java 21
- Cache Maven dependencies
- Run: mvn clean package
- Publish test results
```

#### Stage 2: Container Build
```yaml
- Build Docker image with tag: {git-tag}
- Tag as latest
- Scan for vulnerabilities (local)
```

#### Stage 3: Push to Registry
```yaml
- Authenticate to AWS (OIDC)
- Push image to ECR
- ECR scanning runs automatically
- Wait for scan results
```

#### Stage 4: Deploy
```yaml
- Update kubeconfig
- Helm upgrade --install
- Wait for rollout (max 5 minutes)
- Verify pod is running
```

#### Stage 5: Validation
```yaml
- Call /health endpoint
- Call /metrics endpoint
- Verify response codes
- Fail if any check fails
```

## Key Design Decisions

### 1. OIDC over Static Credentials
- **Why**: No credentials to rotate, audit trail in GitHub, follows AWS best practices
- **Trade-off**: Requires AWS account setup, but one-time cost

### 2. Multi-stage Docker Build
- **Why**: Reduces image size by 70%, faster pulls, smaller attack surface
- **Trade-off**: Slightly more complex Dockerfile

### 3. Helm for Deployment
- **Why**: Templating, versioning, easy rollback, industry standard
- **Trade-off**: Learning curve, but essential for senior-level DevOps

### 4. ECR Native Scanning
- **Why**: Integrated with AWS, no additional tools, automatic on push
- **Trade-off**: Limited to ECR (not portable to other registries)

### 5. Semantic Versioning from Git Tags
- **Why**: Correlates code versions with deployments, easy to track
- **Trade-off**: Requires discipline in tagging strategy

## Error Handling & Rollback

- **Build Failure**: Pipeline stops, developer notified
- **Image Scan Failure**: Pipeline stops, security review required
- **Deployment Failure**: Helm rollback to previous release
- **Health Check Failure**: Deployment marked failed, manual intervention

## Monitoring & Observability

- **Pipeline Logs**: GitHub Actions UI + CloudWatch
- **Application Logs**: EKS pod logs via `kubectl logs`
- **Metrics**: Prometheus scrape `/metrics` endpoint
- **Alerts**: CloudWatch alarms on deployment failures

## Security Considerations

- No credentials in code or environment variables
- ECR image scanning enabled
- IAM role follows least-privilege principle
- Helm values don't contain secrets (use AWS Secrets Manager for runtime secrets)
- Network policies can be added later for pod-to-pod communication

## Performance Targets

- Build time: 2-3 minutes
- Docker build: 1-2 minutes
- ECR push: 30 seconds
- Helm deploy: 1-2 minutes
- Total pipeline: 5-8 minutes

## Future Enhancements

- Canary deployments (Flagger)
- Blue-green deployments
- Automated rollback on metrics
- Multi-region deployment
- GitOps (ArgoCD)
