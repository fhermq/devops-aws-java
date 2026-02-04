# E2E Test Plan - Complete DevOps Pipeline

## Objective
End-to-end testing of the complete DevOps pipeline: infrastructure deployment, microservice deployment with Helm, endpoint validation, and CI/CD pipeline verification.

---

## Phase 1: Infrastructure Deployment ✅ COMPLETE

**Status:** ✅ PASSED (February 3, 2026)
- Deployed 32 resources successfully
- Validated all infrastructure created correctly
- Destroyed all resources with zero orphaned resources
- Validation: 8/8 checks passed

---

## Phase 2: Deploy Microservice with Helm ⏳ IN PROGRESS

### Objective
Deploy the Spring Boot microservice to the EKS cluster using Helm charts with AWS Load Balancer Controller, validate all endpoints, and verify auto-scaling.

### Prerequisites
- ✅ Phase 1 infrastructure deployed and validated
- ✅ Docker image built and tested locally
- ✅ Helm chart created with values for dev/prod
- ✅ kubectl configured to access EKS cluster
- ✅ AWS Load Balancer Controller IAM role created via Terraform IaC

### Step 1: Deploy Infrastructure (Redeploy)
```bash
terraform -chdir=terraform init
terraform -chdir=terraform apply -auto-approve
```

**Estimated time:** 15-20 minutes

**Expected output:**
- 32 resources created
- EKS cluster endpoint available
- Worker nodes in READY state
- AWS Load Balancer Controller IAM role created

### Step 2: Configure kubectl
```bash
aws eks update-kubeconfig --region us-east-1 --name devops-aws-java-cluster
kubectl get nodes
```

**Expected output:**
```
NAME                          STATUS   ROLES    AGE   VERSION
ip-10-0-0-42.ec2.internal    Ready    <none>   5m    v1.30.14-eks-ecaa3a6
ip-10-0-0-55.ec2.internal    Ready    <none>   5m    v1.30.14-eks-ecaa3a6
```

### Step 3: Build and Push Docker Image to ECR
```bash
# Get ECR login token
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Build image
docker build -t devops-aws-java:latest .

# Tag for ECR
docker tag devops-aws-java:latest YOUR_AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/devops-aws-java:latest

# Push to ECR
docker push YOUR_AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/devops-aws-java:latest
```

**Expected output:**
- Image successfully pushed to ECR
- Image available for deployment

### Step 4: Deploy AWS Load Balancer Controller
```bash
# Get the IAM role ARN from Terraform output
AWS_LB_CONTROLLER_ROLE_ARN=$(terraform -chdir=terraform output -raw aws_load_balancer_controller_role_arn)

# Deploy the controller
helm install aws-load-balancer-controller ./helm/aws-load-balancer-controller \
  -n kube-system \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=$AWS_LB_CONTROLLER_ROLE_ARN \
  --set clusterName=devops-aws-java-cluster \
  --set awsRegion=us-east-1
```

**Expected output:**
```
NAME: aws-load-balancer-controller
NAMESPACE: kube-system
STATUS: deployed
```

### Step 5: Verify Load Balancer Controller
```bash
kubectl get pods -n kube-system | grep aws-load-balancer-controller
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller --tail=20
```

**Expected output:**
- 2 controller pods running
- No errors in logs

### Step 6: Deploy Microservice with Helm
```bash
helm install devops-aws-java ./helm/microservice \
  --namespace default \
  --values ./helm/microservice/values-prod.yaml \
  --set image.registry=YOUR_AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com \
  --set image.repository=devops-aws-java \
  --set image.tag=latest
```

**Expected output:**
```
NAME: devops-aws-java
NAMESPACE: default
STATUS: deployed
REVISION: 1
```

### Step 7: Verify Deployment
```bash
# Check pods
kubectl get pods -n default

# Check services
kubectl get svc -n default

# Wait for LoadBalancer external IP (may take 1-2 minutes)
kubectl get svc devops-aws-java-microservice -n default --watch
```

**Expected output:**
```
NAME                              READY   STATUS    RESTARTS   AGE
devops-aws-java-microservice-xxxxx   1/1     Running   0          2m
devops-aws-java-microservice-xxxxx   1/1     Running   0          2m
devops-aws-java-microservice-xxxxx   1/1     Running   0          2m

NAME                           TYPE           CLUSTER-IP      EXTERNAL-IP                                            PORT(S)        AGE
devops-aws-java-microservice   LoadBalancer   172.20.x.x      a1234567890abcdef-1234567890.us-east-1.elb.amazonaws.com   80:30123/TCP   2m
```

### Step 8: Test Endpoints
```bash
# Get LoadBalancer endpoint
LB_ENDPOINT=$(kubectl get svc devops-aws-java-microservice -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test health endpoint
curl http://$LB_ENDPOINT/health

# Test ready endpoint
curl http://$LB_ENDPOINT/ready

# Test API endpoint
curl http://$LB_ENDPOINT/api/hello

# Test metrics endpoint
curl http://$LB_ENDPOINT/actuator/prometheus
```

**Expected output:**
```
# Health endpoint
{"status":"UP"}

# Ready endpoint
{"status":"UP"}

# API endpoint
{"message":"Hello, World!"}

# Metrics endpoint
# HELP jvm_memory_used_bytes The amount of used memory
# TYPE jvm_memory_used_bytes gauge
...
```

### Step 9: Verify Auto-Scaling
```bash
# Check HPA status
kubectl get hpa -n default

# Generate load (optional)
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://devops-aws-java-microservice/api/hello; done"

# Monitor scaling
kubectl get hpa -n default --watch
```

**Expected output:**
```
NAME               REFERENCE                     TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
devops-aws-java    Deployment/devops-aws-java    5%/80%    3         10        3          5m
```

### Step 10: Cleanup (Destroy)
```bash
# Delete Helm releases
helm uninstall aws-load-balancer-controller -n kube-system
helm uninstall devops-aws-java -n default

# Destroy infrastructure
terraform -chdir=terraform destroy -auto-approve

# Validate cleanup
bash terraform/validate-infrastructure-destroyed.sh
```

---

## Phase 2: Success Criteria

- [ ] Infrastructure redeployed successfully
- [ ] kubectl configured and nodes visible
- [ ] Docker image built and pushed to ECR
- [ ] AWS Load Balancer Controller deployed successfully
- [ ] Controller pods running without errors
- [ ] Helm deployment successful
- [ ] All pods running
- [ ] LoadBalancer external IP provisioned
- [ ] Health endpoint returns UP
- [ ] Ready endpoint returns UP
- [ ] API endpoint returns correct response
- [ ] Metrics endpoint returns Prometheus data
- [ ] HPA configured and monitoring
- [ ] Infrastructure destroyed with zero orphaned resources

---

## Phase 3: GitHub Actions Pipeline Testing ⏳ TODO

### Objective
Verify the CI/CD pipeline works end-to-end with the three-branch strategy.

### Prerequisites
- ✅ Phase 2 microservice deployment validated
- ✅ GitHub repository configured
- ✅ GitHub Actions secrets configured
- ✅ ECR repository created

### Steps
1. Create develop branch
2. Push code to develop (triggers build & test only)
3. Create stage branch from develop
4. Push to stage (triggers build & test only)
5. Create PR to main
6. Merge to main (triggers build, test, and auto-deploy to EKS)
7. Verify deployment in EKS
8. Run smoke tests

---

## Phase 4: End-to-End Validation ⏳ TODO

### Objective
Complete validation of the entire pipeline from code commit to production deployment.

### Steps
1. Modify microservice code
2. Commit to develop branch
3. Verify build and test in GitHub Actions
4. Merge to main
5. Verify auto-deployment to EKS
6. Test all endpoints
7. Verify metrics collection
8. Verify auto-scaling behavior

---

## Success Criteria Summary

### Phase 1 ✅
- [x] Infrastructure deployed
- [x] All resources validated
- [x] Infrastructure destroyed
- [x] Zero orphaned resources

### Phase 2 ⏳
- [ ] AWS Load Balancer Controller deployed via Terraform IAM role
- [ ] Microservice deployed with Helm
- [ ] All endpoints accessible via LoadBalancer
- [ ] Auto-scaling configured
- [ ] Infrastructure cleaned up

### Phase 3 ⏳
- [ ] GitHub Actions pipeline working
- [ ] Three-branch strategy validated
- [ ] Auto-deployment to main working

### Phase 4 ⏳
- [ ] End-to-end pipeline validated
- [ ] All components working together

---

## Commands Quick Reference

### Phase 1 (Infrastructure)
```bash
terraform -chdir=terraform init
terraform -chdir=terraform plan -out=tfplan
terraform -chdir=terraform apply tfplan
bash terraform/validate-infrastructure-created.sh
terraform -chdir=terraform destroy -auto-approve
bash terraform/validate-infrastructure-destroyed.sh
```

### Phase 2 (Microservice Deployment with Load Balancer)
```bash
# Deploy infrastructure
terraform -chdir=terraform apply -auto-approve

# Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name devops-aws-java-cluster

# Build and push image
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
docker build -t devops-aws-java:latest .
docker tag devops-aws-java:latest YOUR_AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/devops-aws-java:latest
docker push YOUR_AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/devops-aws-java:latest

# Deploy AWS Load Balancer Controller
AWS_LB_CONTROLLER_ROLE_ARN=$(terraform -chdir=terraform output -raw aws_load_balancer_controller_role_arn)
helm install aws-load-balancer-controller ./helm/aws-load-balancer-controller \
  -n kube-system \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=$AWS_LB_CONTROLLER_ROLE_ARN \
  --set clusterName=devops-aws-java-cluster \
  --set awsRegion=us-east-1

# Deploy with Helm
helm install devops-aws-java ./helm/microservice \
  --namespace default \
  --values ./helm/microservice/values-prod.yaml \
  --set image.registry=YOUR_AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com \
  --set image.repository=devops-aws-java \
  --set image.tag=latest

# Verify deployment
kubectl get pods -n default
kubectl get svc -n default

# Test endpoints
LB_ENDPOINT=$(kubectl get svc devops-aws-java-microservice -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl http://$LB_ENDPOINT/health
curl http://$LB_ENDPOINT/api/hello

# Cleanup
helm uninstall aws-load-balancer-controller -n kube-system
helm uninstall devops-aws-java -n default
terraform -chdir=terraform destroy -auto-approve
```

---

## Important Notes

1. **Phase 1 is complete** - Infrastructure deployment and cleanup validated
2. **Phase 2 is next** - Microservice deployment with AWS Load Balancer Controller
3. **AWS Load Balancer Controller** - Now managed via Terraform IAM role (IaC approach)
4. **Estimated time for Phase 2:** 30-40 minutes (including infrastructure deployment)
5. **Cost for Phase 2:** ~$0.41 (same as Phase 1)
6. **All phases are repeatable** - Can run multiple times for testing

---

**Status:** Phase 1 ✅ Complete | Phase 2 ⏳ Ready to Start (with Load Balancer Controller)
**Last Updated:** February 3, 2026
