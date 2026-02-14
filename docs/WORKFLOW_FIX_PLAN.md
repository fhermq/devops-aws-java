# Phase 3 Workflow Fix Plan

**Date**: February 14, 2026  
**Status**: IN PROGRESS - Implementation Complete, Awaiting Destroy & Redeploy  
**Objective**: Fix Phase 3 deployment workflow to only trigger on app changes and resolve EKS update failures

> ⚠️ **TEMPORARY DOCUMENT**: This file should be deleted once the fixes are completed and validated in production. See `docs/SESSION_SUMMARY.md` for tracking.

---

## Implementation Status

### ✅ COMPLETED - All Code Changes Implemented

#### Fix 1: Workflow Trigger Conditions ✅ DONE
**File**: `.github/workflows/phase-3-deploy-app.yml`
- ✅ Changed from `paths-ignore` to `paths` filter
- ✅ Now only triggers on: `app/**` and `.github/workflows/phase-3-deploy-app.yml`
- ✅ Ignores: infrastructure/, docs/, terraform/, and other changes

#### Fix 2: Helm Values - imagePullPolicy ✅ DONE
**File**: `infrastructure/helm/microservice/values.yaml`
- ✅ Changed `pullPolicy: IfNotPresent` → `pullPolicy: Always`
- ✅ Added `deploymentStrategy` section with RollingUpdate configuration
- ✅ maxSurge: 1, maxUnavailable: 0 for zero-downtime updates

#### Fix 3: Production Values - imagePullPolicy ✅ DONE
**File**: `infrastructure/helm/microservice/values-prod.yaml`
- ✅ Changed `pullPolicy: IfNotPresent` → `pullPolicy: Always`

#### Fix 4: Deployment Template ✅ DONE
**File**: `infrastructure/helm/microservice/templates/deployment.yaml`
- ✅ Added deployment strategy configuration
- ✅ Added pod restart annotation for tracking

#### Fix 5: Workflow Deploy Step ✅ DONE
**File**: `.github/workflows/phase-3-deploy-app.yml`
- ✅ Added `kubectl rollout restart deployment/microservice` after Helm upgrade
- ✅ Added status check after restart
- ✅ Added logging for debugging

### ✅ COMPLETED - Workflow Simplifications

#### Phase 2 Workflow Simplification ✅ DONE
**File**: `.github/workflows/phase-2-eks.yml`
- ✅ Removed entire `deploy-nginx-test` job (was for validation only)
- ✅ Removed nginx test cleanup from destroy workflow
- ✅ Kept Load Balancer Controller installation (infrastructure setup)
- **Result**: Phase 2 now only deploys infrastructure (VPC, EKS, Load Balancer Controller)

#### Phase 3 Workflow Simplification ✅ DONE
**File**: `.github/workflows/phase-3-deploy-app.yml`
- ✅ Removed `Install AWS Load Balancer Controller` step (already in Phase 2)
- ✅ Kept all app deployment logic
- **Result**: Phase 3 now only deploys the Java application

### ⏳ PENDING - Infrastructure Destroy & Redeploy

#### Step 1: Trigger Destroy Workflow ⏳ PENDING
- User to trigger Phase 2 destroy workflow from GitHub Actions
- Expected duration: 15-20 minutes
- Validates destroy workflow works correctly

#### Step 2: Verify Cleanup ⏳ PENDING
- Run validation script: `bash infrastructure/scripts/phase-2-check-orphaned.sh`
- Ensure no orphaned resources remain
- Expected duration: 2 minutes

#### Step 3: Commit & Push Changes ⏳ PENDING
- Commit all workflow and Helm changes
- Push to main branch
- Expected duration: 1 minute

#### Step 4: Redeploy Phase 2 ⏳ PENDING
- Trigger Phase 2 apply workflow from GitHub Actions
- Deploy with simplified workflow (no nginx test)
- Expected duration: 20 minutes

#### Step 5: Redeploy Phase 3 ⏳ PENDING
- Trigger Phase 3 deploy workflow from GitHub Actions
- Deploy Java app with pod restart fixes
- Expected duration: 10 minutes

#### Step 6: Validate Deployment ⏳ PENDING
- Test all endpoints responding
- Verify pods running with correct image
- Test app update scenario

---

## Issues to Fix

### Issue 1: Workflow Triggers on Entire Project Changes
**Problem**: 
- Phase 3 workflow currently triggers on ANY push to main/stage/develop branches
- Triggers even when only infrastructure or docs change
- Wastes CI/CD resources and causes unnecessary deployments
- Current `paths-ignore` only excludes `terraform/**` and `.github/workflows/terraform.yml`

**Current Behavior**:
```yaml
on:
  push:
    branches:
      - develop
      - stage
      - main
    tags:
      - 'v*'
    paths-ignore:
      - 'terraform/**'
      - '.github/workflows/terraform.yml'
```

**Impact**:
- ❌ Triggers on docs/ changes
- ❌ Triggers on infrastructure/ changes (except terraform/)
- ❌ Triggers on .github/workflows/phase-2-eks.yml changes
- ✅ Only ignores terraform/ and phase-2-eks.yml

---

### Issue 2: Application Update Fails on EKS Cluster
**Problem**:
- When deploying updated microservice image, pods fail to update
- Likely causes:
  1. Image pull policy not set to `Always` (pods use cached old image)
  2. Helm deployment not forcing pod restart on image update
  3. Missing `imagePullPolicy: Always` in Helm values
  4. Deployment strategy not configured for rolling updates
  5. Image tag not changing (using `latest` tag without forcing refresh)

**Current Behavior**:
- Helm upgrade succeeds ("Happy Helming!")
- But pods continue running old image
- No pod restart triggered

**Impact**:
- ❌ Code changes don't deploy to cluster
- ❌ Users see old version of application
- ❌ Defeats purpose of CI/CD pipeline

---

## Solution Plan

### Fix 1: Restrict Workflow to App Changes Only

**Approach**: Use `paths` (instead of `paths-ignore`) to explicitly include only app changes

**Changes**:
```yaml
on:
  push:
    branches:
      - develop
      - stage
      - main
    tags:
      - 'v*'
    paths:
      - 'app/**'           # Only trigger on app/ changes
      - '.github/workflows/phase-3-deploy-app.yml'  # Allow workflow self-updates
  pull_request:
    branches:
      - develop
      - stage
      - main
    paths:
      - 'app/**'
```

**Benefits**:
- ✅ Only triggers on actual app code changes
- ✅ Ignores infrastructure/, docs/, and other changes
- ✅ Saves CI/CD resources
- ✅ Clearer intent and behavior

**Files to Modify**:
- `.github/workflows/phase-3-deploy-app.yml` (lines 5-20)

---

### Fix 2: Force Pod Restart on Image Update

**Approach**: Implement multiple strategies to ensure pods restart with new image

**Strategy A: Update Helm Values**
- Add `imagePullPolicy: Always` to force image pull on every pod start
- Add `restartPolicy: Always` to deployment
- Use image tag that changes with each build (not just `latest`)

**Strategy B: Force Deployment Rollout**
- Add `kubectl rollout restart` command after Helm upgrade
- Ensures pods restart even if image tag hasn't changed

**Strategy C: Add Deployment Annotation**
- Add timestamp annotation to force pod recreation
- Helm will detect change and restart pods

**Recommended**: Combine Strategy A + B for reliability

**Changes to Make**:

1. **Update `infrastructure/helm/microservice/values.yaml`**:
```yaml
image:
  pullPolicy: Always  # Force pull on every pod start

deployment:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
```

2. **Update `infrastructure/helm/microservice/templates/deployment.yaml`**:
```yaml
spec:
  template:
    metadata:
      annotations:
        deployment.kubernetes.io/revision: "{{ .Release.Revision }}"
    spec:
      containers:
      - name: microservice
        imagePullPolicy: Always  # Explicit pull policy
```

3. **Update Phase 3 Workflow Deploy Step**:
```bash
# After Helm upgrade, force pod restart
helm upgrade --install microservice infrastructure/helm/microservice \
  -f infrastructure/helm/microservice/values-prod.yaml \
  --set image.registry=... \
  --set service.type=LoadBalancer \
  --timeout 15m

# Force pod restart to pick up new image
echo "Forcing pod restart..."
kubectl rollout restart deployment/microservice -n default
kubectl rollout status deployment/microservice --timeout=5m || true
```

**Files to Modify**:
- `infrastructure/helm/microservice/values.yaml`
- `infrastructure/helm/microservice/values-prod.yaml`
- `infrastructure/helm/microservice/templates/deployment.yaml`
- `.github/workflows/phase-3-deploy-app.yml` (deploy step)

---

## Implementation Steps

### Step 1: Update Workflow Trigger Conditions
**File**: `.github/workflows/phase-3-deploy-app.yml`
**Changes**:
- Replace `paths-ignore` with `paths` to only include `app/**`
- Add workflow file to paths for self-updates
- Apply to both `push` and `pull_request` triggers

**Expected Result**: Workflow only triggers on app code changes

---

### Step 2: Update Helm Values
**Files**: 
- `infrastructure/helm/microservice/values.yaml`
- `infrastructure/helm/microservice/values-prod.yaml`

**Changes**:
- Add `imagePullPolicy: Always`
- Add rolling update strategy
- Add pod restart annotations

**Expected Result**: Pods will pull latest image on restart

---

### Step 3: Update Helm Deployment Template
**File**: `infrastructure/helm/microservice/templates/deployment.yaml`

**Changes**:
- Ensure `imagePullPolicy: Always` is set
- Add revision annotation for pod restart tracking
- Verify rolling update strategy

**Expected Result**: Deployment will restart pods on image update

---

### Step 4: Update Workflow Deploy Step
**File**: `.github/workflows/phase-3-deploy-app.yml`

**Changes**:
- Add `kubectl rollout restart` after Helm upgrade
- Add status check with error handling
- Add logging for debugging

**Expected Result**: Pods restart immediately after Helm upgrade

---

## Testing Plan

### Test 1: Verify Workflow Trigger Conditions
1. Make change to `docs/README.md` → Workflow should NOT trigger
2. Make change to `infrastructure/terraform/main.tf` → Workflow should NOT trigger
3. Make change to `app/src/main/java/...` → Workflow SHOULD trigger
4. Make change to `.github/workflows/phase-3-deploy-app.yml` → Workflow SHOULD trigger

### Test 2: Verify Pod Update on Image Change
1. Deploy initial version (v1.0)
2. Verify pods running with v1.0 image
3. Update app code (e.g., change API response)
4. Push to main branch
5. Wait for workflow to complete
6. Verify pods running with new image
7. Test endpoint returns updated response

### Test 3: Verify No Unnecessary Deployments
1. Make infrastructure change
2. Verify Phase 3 workflow does NOT trigger
3. Verify Phase 2 workflow CAN still be triggered manually

---

## Rollback Plan

If issues occur:
1. Revert workflow changes: `git revert <commit>`
2. Revert Helm changes: `git revert <commit>`
3. Manually restart pods: `kubectl rollout restart deployment/microservice`
4. Check pod logs: `kubectl logs -f deployment/microservice`

---

## Success Criteria

✅ Phase 3 workflow only triggers on app code changes  
✅ Phase 3 workflow does NOT trigger on infrastructure/docs changes  
✅ Updated app code deploys successfully to EKS  
✅ Pods restart with new image after Helm upgrade  
✅ Endpoints return updated responses  
✅ No orphaned resources created  
✅ Rollback works correctly  

---

## Files to Modify

| File | Changes | Priority |
|------|---------|----------|
| `.github/workflows/phase-3-deploy-app.yml` | Update trigger paths + add rollout restart | HIGH |
| `infrastructure/helm/microservice/values.yaml` | Add imagePullPolicy: Always | HIGH |
| `infrastructure/helm/microservice/values-prod.yaml` | Add imagePullPolicy: Always | HIGH |
| `infrastructure/helm/microservice/templates/deployment.yaml` | Ensure imagePullPolicy: Always | HIGH |

---

## Estimated Effort

- Workflow trigger fix: 5 minutes
- Helm values update: 10 minutes
- Helm template update: 10 minutes
- Workflow deploy step update: 10 minutes
- Testing: 30 minutes
- **Total**: ~65 minutes

---

**Next Action**: Proceed with implementation once plan is approved

