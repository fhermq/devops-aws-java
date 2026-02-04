# CI/CD Workflow Summary

## Updated GitHub Actions Pipeline

The workflow now supports a **three-branch strategy** with progressive validation and auto-deployment only on main.

### Branch Strategy

```
develop (Development)
    ↓ (PR + Merge)
stage (Staging)
    ↓ (PR + Merge)
main (Production) → Auto-Deploy
```

## Pipeline Behavior by Branch

### 1. Develop Branch
**Trigger**: Push to `develop`

**Pipeline**:
- ✓ Build & Test (Maven)
- ✓ Build Docker Image (tag: `develop-{commit-hash}`)
- ✓ Push to ECR
- ✓ Smoke Tests

**Deployment**: ❌ No deployment

**Purpose**: Fast feedback, catch bugs early

**Image Tag Example**: `develop-a1b2c3d`

---

### 2. Stage Branch
**Trigger**: Push to `stage`

**Pipeline**:
- ✓ Build & Test (Maven)
- ✓ Build Docker Image (tag: `stage-{commit-hash}`)
- ✓ Push to ECR
- ✓ Smoke Tests

**Deployment**: ❌ No deployment (manual testing)

**Purpose**: Integration testing, code review, QA validation

**Image Tag Example**: `stage-x9y8z7w`

---

### 3. Main Branch
**Trigger**: Push to `main` or tag `v*`

**Pipeline**:
- ✓ Build & Test (Maven)
- ✓ Build Docker Image (tag: `latest` or `v1.0.0`)
- ✓ Push to ECR
- ✓ Smoke Tests
- ✓ **Auto-Deploy to EKS** (NEW!)

**Deployment**: ✅ Auto-deploy to production

**Purpose**: Production-ready code, automatic deployment

**Image Tag Examples**: `latest`, `v1.0.0`, `v1.1.0`

---

## Workflow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Feature Development                      │
│                                                             │
│  1. Create feature branch from develop                      │
│  2. Make changes & commit                                   │
│  3. Push to GitHub                                          │
│  4. Create PR to develop                                    │
│  5. Code review & merge                                     │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
        ┌────────────────────────────┐
        │  GitHub Actions (develop)  │
        │  - Build & Test            │
        │  - Build Image             │
        │  - Push to ECR             │
        │  - Smoke Tests             │
        │  ❌ No Deployment          │
        └────────────────┬───────────┘
                         │
                         ▼
        ┌────────────────────────────┐
        │  Code Review & Testing     │
        │  - Manual testing          │
        │  - QA validation           │
        │  - Approval                │
        └────────────────┬───────────┘
                         │
                         ▼
        ┌────────────────────────────┐
        │  Merge to stage            │
        │  git merge develop         │
        │  git push origin stage     │
        └────────────────┬───────────┘
                         │
                         ▼
        ┌────────────────────────────┐
        │  GitHub Actions (stage)    │
        │  - Build & Test            │
        │  - Build Image             │
        │  - Push to ECR             │
        │  - Smoke Tests             │
        │  ❌ No Deployment          │
        └────────────────┬───────────┘
                         │
                         ▼
        ┌────────────────────────────┐
        │  Final Code Review         │
        │  - Production readiness    │
        │  - Approval                │
        └────────────────┬───────────┘
                         │
                         ▼
        ┌────────────────────────────┐
        │  Merge to main             │
        │  git merge stage           │
        │  git push origin main      │
        └────────────────┬───────────┘
                         │
                         ▼
        ┌────────────────────────────┐
        │  GitHub Actions (main)     │
        │  - Build & Test            │
        │  - Build Image             │
        │  - Push to ECR             │
        │  - Smoke Tests             │
        │  ✅ Auto-Deploy to EKS     │
        └────────────────────────────┘
                         │
                         ▼
        ┌────────────────────────────┐
        │  Production Deployment     │
        │  - Helm upgrade            │
        │  - Rollout verification    │
        │  - Service available       │
        └────────────────────────────┘
```

## Image Tagging Strategy

### Develop Branch
```
develop-a1b2c3d  (commit hash)
latest            (always latest develop)
```

### Stage Branch
```
stage-x9y8z7w    (commit hash)
latest            (always latest stage)
```

### Main Branch
```
v1.0.0            (semantic version tag)
latest            (always latest production)
```

## Auto-Deployment Details

### Triggered On
- Push to `main` branch
- Git tag `v*` (e.g., `v1.0.0`)

### Deployment Process
1. Checkout code
2. Configure AWS credentials (OIDC)
3. Update kubeconfig
4. Helm upgrade/install to production
5. Wait for rollout
6. Verify deployment

### Helm Values Used
- `helm/microservice/values-prod.yaml`
- 3 replicas
- Auto-scaling 3-10 pods
- Higher resource limits

### Rollback
If deployment fails:
```bash
helm rollback microservice
```

## Git Commands Reference

### Create Feature Branch
```bash
git checkout develop
git pull origin develop
git checkout -b feature/my-feature
```

### Merge to Develop
```bash
git push origin feature/my-feature
# Create PR on GitHub, get approval, merge
```

### Promote to Stage
```bash
git checkout stage
git pull origin stage
git merge develop
git push origin stage
```

### Promote to Main
```bash
git checkout main
git pull origin main
git merge stage
git push origin main
```

### Create Release Tag
```bash
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

## Branch Protection Rules (Recommended)

### Main Branch
- Require 1 pull request review
- Require status checks to pass
- Require branches to be up to date
- Dismiss stale pull request approvals

### Stage Branch
- Require 1 pull request review
- Require status checks to pass

### Develop Branch
- Require status checks to pass

## Monitoring Deployments

### View Pipeline Status
- GitHub Actions tab → Workflows
- Click on workflow run to see details

### View Deployment Logs
```bash
kubectl logs -f deployment/microservice
```

### Check Rollout Status
```bash
kubectl rollout status deployment/microservice
```

### View Service URL
```bash
kubectl get svc microservice -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

## Troubleshooting

### Pipeline Failed
1. Check GitHub Actions logs
2. Review error message
3. Fix code locally
4. Push fix to same branch
5. Pipeline re-runs automatically

### Deployment Failed
1. Check Helm logs: `helm status microservice`
2. Check pod logs: `kubectl logs deployment/microservice`
3. Rollback: `helm rollback microservice`
4. Fix issue and re-push to main

### Image Not Found in ECR
1. Verify image was pushed: `aws ecr describe-images --repository-name devops-aws-java`
2. Check GitHub Actions logs for push errors
3. Verify AWS credentials are correct

## Next Steps

1. **Tomorrow**: Test E2E with manual deployment
2. **After E2E**: Push code to GitHub
3. **Test Pipeline**: 
   - Push to develop → verify image created
   - Merge to stage → verify image created
   - Merge to main → verify auto-deployment
4. **Production**: Use main branch for all production deployments

## References

- [CONTRIBUTING.md](CONTRIBUTING.md) - Git workflow guide
- [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Deployment instructions
- [README.md](README.md) - Project overview
- [.github/workflows/deploy.yml](.github/workflows/deploy.yml) - Workflow definition
