# Java Microservice DevOps Pipeline - Implementation Tasks

## Phase 1: Spring Boot Microservice Foundation

- [x] 1.1 Create Spring Boot project structure
  - [x] 1.1.1 Initialize Maven project with pom.xml
  - [x] 1.1.2 Add Spring Boot dependencies (web, actuator)
  - [x] 1.1.3 Create main application class
  - [x] 1.1.4 Configure application.properties

- [x] 1.2 Implement health check endpoints
  - [x] 1.2.1 Create /health endpoint (liveness probe)
  - [x] 1.2.2 Create /ready endpoint (readiness probe)
  - [x] 1.2.3 Create /metrics endpoint (Prometheus format)
  - [x] 1.2.4 Add unit tests for endpoints

- [x] 1.3 Create sample API endpoint
  - [x] 1.3.1 Create /api/hello endpoint
  - [x] 1.3.2 Add request/response models
  - [x] 1.3.3 Add unit tests

## Phase 2: Docker & Container Strategy

- [x] 2.1 Create multi-stage Dockerfile
  - [x] 2.1.1 Build stage (Maven)
  - [x] 2.1.2 Runtime stage (JRE)
  - [x] 2.1.3 Optimize image size
  - [x] 2.1.4 Test locally with `docker build`

- [x] 2.2 Create .dockerignore file
  - [x] 2.2.1 Exclude unnecessary files
  - [x] 2.2.2 Optimize build context

## Phase 3: AWS Infrastructure (Terraform)

- [ ] 3.1 Create Terraform configuration
  - [ ] 3.1.1 Create main.tf with provider config
  - [ ] 3.1.2 Create variables.tf with input variables
  - [ ] 3.1.3 Create outputs.tf with outputs

- [ ] 3.2 Create ECR repository
  - [ ] 3.2.1 Define ECR repository resource
  - [ ] 3.2.2 Enable image scanning
  - [ ] 3.2.3 Create lifecycle policy (keep last 10 images)
  - [ ] 3.2.4 Output ECR registry URL

- [ ] 3.3 Create IAM role for GitHub OIDC
  - [ ] 3.3.1 Create OIDC provider for GitHub
  - [ ] 3.3.2 Create IAM role with trust relationship
  - [ ] 3.3.3 Attach policy for ECR push/pull
  - [ ] 3.3.4 Output role ARN

- [ ] 3.4 Deploy Terraform
  - [ ] 3.4.1 Run `terraform init`
  - [ ] 3.4.2 Run `terraform plan` and review
  - [ ] 3.4.3 Run `terraform apply`
  - [ ] 3.4.4 Verify ECR repository created
  - [ ] 3.4.5 Verify IAM role created

## Phase 4: GitHub Actions Pipeline

- [x] 4.1 Create GitHub Actions workflow file
  - [x] 4.1.1 Create .github/workflows/deploy.yml
  - [x] 4.1.2 Define trigger events (push, pull_request)
  - [x] 4.1.3 Set environment variables

- [x] 4.2 Implement build & test stage
  - [x] 4.2.1 Checkout code
  - [x] 4.2.2 Setup Java 21
  - [x] 4.2.3 Cache Maven dependencies
  - [x] 4.2.4 Run Maven build and tests
  - [x] 4.2.5 Publish test results

- [x] 4.3 Implement Docker build stage
  - [x] 4.3.1 Build Docker image with semantic versioning
  - [x] 4.3.2 Tag image with git tag and latest
  - [x] 4.3.3 Scan image locally (optional)

- [x] 4.4 Implement AWS authentication (OIDC)
  - [x] 4.4.1 Configure OIDC token request
  - [x] 4.4.2 Assume IAM role using OIDC token
  - [x] 4.4.3 Verify credentials work

- [x] 4.5 Implement ECR push stage
  - [x] 4.5.1 Login to ECR
  - [x] 4.5.2 Push image to ECR
  - [x] 4.5.3 Wait for ECR scanning to complete
  - [x] 4.5.4 Fail if vulnerabilities found (configurable)

- [x] 4.6 Implement deployment stage
  - [x] 4.6.1 Update kubeconfig
  - [x] 4.6.2 Helm upgrade --install
  - [x] 4.6.3 Wait for rollout to complete
  - [x] 4.6.4 Verify pod is running

- [x] 4.7 Implement smoke tests
  - [x] 4.7.1 Call /health endpoint
  - [x] 4.7.2 Call /metrics endpoint
  - [x] 4.7.3 Verify response codes
  - [x] 4.7.4 Fail deployment if checks fail

## Phase 5: Helm Chart

- [x] 5.1 Create Helm chart structure
  - [x] 5.1.1 Create Chart.yaml
  - [x] 5.1.2 Create values.yaml with defaults
  - [x] 5.1.3 Create values-dev.yaml
  - [x] 5.1.4 Create values-prod.yaml

- [x] 5.2 Create Kubernetes templates
  - [x] 5.2.1 Create deployment.yaml template
  - [x] 5.2.2 Create service.yaml template
  - [x] 5.2.3 Create configmap.yaml template
  - [x] 5.2.4 Add health probes to deployment
  - [x] 5.2.5 Add resource limits

- [x] 5.3 Test Helm chart locally
  - [x] 5.3.1 Run `helm lint`
  - [x] 5.3.2 Run `helm template` and review output
  - [ ] 5.3.3 Deploy to local cluster (minikube/kind)
  - [ ] 5.3.4 Verify deployment works

## Phase 6: End-to-End Testing

- [ ] 6.1 Test pipeline locally
  - [ ] 6.1.1 Build Docker image locally
  - [ ] 6.1.2 Run container and test endpoints
  - [ ] 6.1.3 Verify health checks work

- [ ] 6.2 Test GitHub Actions workflow
  - [ ] 6.2.1 Push code to GitHub
  - [ ] 6.2.2 Verify workflow triggers
  - [ ] 6.2.3 Monitor build stage
  - [ ] 6.2.4 Monitor Docker build stage
  - [ ] 6.2.5 Monitor ECR push stage
  - [ ] 6.2.6 Monitor deployment stage
  - [ ] 6.2.7 Verify smoke tests pass

- [ ] 6.3 Test rollback scenario
  - [ ] 6.3.1 Deploy version 1
  - [ ] 6.3.2 Deploy version 2
  - [ ] 6.3.3 Rollback to version 1 using Helm
  - [ ] 6.3.4 Verify rollback works

- [ ] 6.4 Test failure scenarios
  - [ ] 6.4.1 Introduce test failure, verify pipeline stops
  - [ ] 6.4.2 Introduce build failure, verify pipeline stops
  - [ ] 6.4.3 Verify error messages are clear

## Phase 7: Documentation & Cleanup

- [x] 7.1 Create README.md
  - [x] 7.1.1 Document project structure
  - [x] 7.1.2 Document setup instructions
  - [x] 7.1.3 Document deployment process
  - [x] 7.1.4 Document troubleshooting guide

- [x] 7.2 Create CONTRIBUTING.md
  - [x] 7.2.1 Document git workflow
  - [x] 7.2.2 Document tagging strategy
  - [x] 7.2.3 Document local development setup

- [x] 7.3 Cleanup and optimization
  - [x] 7.3.1 Remove unused files
  - [x] 7.3.2 Optimize Dockerfile
  - [x] 7.3.3 Review and optimize workflow
  - [x] 7.3.4 Add comments to complex sections

## Notes

- Each task should be completed in order
- Sub-tasks must be completed before parent task is marked complete
- Test each phase before moving to the next
- Document any issues or learnings as you go
