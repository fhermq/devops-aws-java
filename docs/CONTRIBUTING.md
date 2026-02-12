# Contributing Guide

## Git Workflow

This project uses a **three-branch strategy** with automated CI/CD:

```
develop → stage → main (production)
```

### Branch Purposes

#### `develop` - Development Branch
- **Purpose**: Active development and feature work
- **Deployment**: No auto-deployment
- **Image Tag**: `develop-{commit-hash}`
- **Pipeline**: Build, Test, Image Creation
- **Use Case**: Daily development, feature branches merge here

#### `stage` - Staging Branch
- **Purpose**: Pre-production testing and integration
- **Deployment**: No auto-deployment (manual testing)
- **Image Tag**: `stage-{commit-hash}`
- **Pipeline**: Build, Test, Image Creation, Smoke Tests
- **Use Case**: Code review, integration testing, QA validation

#### `main` - Production Branch
- **Purpose**: Production-ready code only
- **Deployment**: Auto-deploy to EKS
- **Image Tag**: `latest` or `v{version}`
- **Pipeline**: Build, Test, Image Creation, Smoke Tests, Auto-Deploy
- **Use Case**: Stable, tested, approved code

## Workflow Steps

### 1. Create Feature Branch
```bash
git checkout develop
git pull origin develop
git checkout -b feature/my-feature
```

### 2. Make Changes & Commit
```bash
git add .
git commit -m "feat: add new feature"
```

### 3. Push to GitHub
```bash
git push origin feature/my-feature
```

### 4. Create Pull Request
- Go to GitHub
- Create PR from `feature/my-feature` → `develop`
- Add description and tests
- Request review

### 5. Code Review & Merge to Develop
- Reviewers approve
- Merge to `develop`
- GitHub Actions runs: Build, Test, Image Creation

### 6. Promote to Stage
```bash
git checkout stage
git pull origin stage
git merge develop
git push origin stage
```

- GitHub Actions runs: Build, Test, Image Creation, Smoke Tests
- Manual testing in staging environment
- Code review for production readiness

### 7. Promote to Main (Production)
```bash
git checkout main
git pull origin main
git merge stage
git push origin main
```

- GitHub Actions runs: Build, Test, Image Creation, Smoke Tests, **Auto-Deploy**
- Automatically deployed to production EKS cluster

## Commit Message Convention

Use conventional commits for clarity:

```
feat: add new feature
fix: fix a bug
docs: update documentation
test: add tests
chore: update dependencies
refactor: refactor code
```

Example:
```bash
git commit -m "feat: add health check endpoint"
git commit -m "fix: resolve memory leak in controller"
git commit -m "test: add unit tests for API"
```

## Versioning

### Semantic Versioning
Use semantic versioning for releases:

```
v{MAJOR}.{MINOR}.{PATCH}
```

Example: `v1.0.0`, `v1.1.0`, `v1.1.1`

### Creating a Release
```bash
# Create tag
git tag -a v1.0.0 -m "Release version 1.0.0"

# Push tag
git push origin v1.0.0
```

- GitHub Actions automatically:
  - Builds image with tag `v1.0.0`
  - Pushes to ECR
  - Runs smoke tests
  - Auto-deploys to production

## GitHub Actions Pipeline

### Develop Branch
```
Push to develop
    ↓
Build & Test (Maven)
    ↓
Build Docker Image (develop-{hash})
    ↓
Push to ECR
    ↓
✓ Complete (no deployment)
```

### Stage Branch
```
Push to stage
    ↓
Build & Test (Maven)
    ↓
Build Docker Image (stage-{hash})
    ↓
Push to ECR
    ↓
Smoke Tests
    ↓
✓ Complete (manual testing)
```

### Main Branch
```
Push to main
    ↓
Build & Test (Maven)
    ↓
Build Docker Image (latest)
    ↓
Push to ECR
    ↓
Smoke Tests
    ↓
Auto-Deploy to EKS
    ↓
✓ Production Deployment Complete
```

## Branch Protection Rules

### Main Branch
- ✓ Require pull request reviews (1 approval)
- ✓ Require status checks to pass
- ✓ Require branches to be up to date
- ✓ Dismiss stale pull request approvals
- ✓ Require code review from code owners

### Stage Branch
- ✓ Require pull request reviews (1 approval)
- ✓ Require status checks to pass

### Develop Branch
- ✓ Require status checks to pass

## Local Development

### Setup
```bash
git clone https://github.com/fhermq/devops-aws-java.git
cd devops-aws-java
git checkout develop
```

### Build Locally
```bash
mvn clean package
```

### Test Locally
```bash
mvn test
```

### Docker Build
```bash
docker build -t devops-aws-java:local .
docker run -p 8080:8080 devops-aws-java:local
```

### Test Endpoints
```bash
curl http://localhost:8080/health
curl http://localhost:8080/api/hello
```

## Code Review Checklist

Before approving a PR, verify:

- [ ] Code follows project conventions
- [ ] Tests are included and passing
- [ ] No hardcoded credentials or secrets
- [ ] Documentation is updated
- [ ] Commit messages are clear
- [ ] No breaking changes (unless major version)
- [ ] Performance impact is acceptable
- [ ] Security best practices followed

## Troubleshooting

### Merge Conflicts
```bash
git checkout develop
git pull origin develop
git merge feature/my-feature
# Resolve conflicts in editor
git add .
git commit -m "resolve merge conflicts"
git push origin develop
```

### Undo Last Commit
```bash
git reset --soft HEAD~1
```

### Force Push (Use Carefully!)
```bash
git push origin feature/my-feature --force
```

## Questions?

Refer to:
- [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Deployment instructions
- [README.md](README.md) - Project overview
- GitHub Issues - Report bugs or ask questions
