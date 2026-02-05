# Security Architecture Plan - Option 1 (Simplified)

**Status:** In Progress - Rebuilding Infrastructure  
**Date:** February 5, 2026  
**Approach:** Simplified, Private-First Architecture

---

## Architecture Overview

### Option 1: Simplified Private-First Design

```
┌─────────────────────────────────────────────────────────────┐
│                        Internet                              │
└────────────────────────┬────────────────────────────────────┘
                         │
                    Your IP Only
                    (ACL Restricted)
                         │
        ┌────────────────▼────────────────┐
        │   Public Subnets (2)            │
        │   - Classic LoadBalancer        │
        │   - No NAT Gateways             │
        │   - No EC2 instances            │
        └────────────────┬────────────────┘
                         │
                    Port 80 (HTTP)
                         │
        ┌────────────────▼────────────────┐
        │   Private Subnets (2)           │
        │   - EKS Cluster                 │
        │   - Worker Nodes                │
        │   - No Internet Access          │
        │   - No NAT Gateways             │
        └─────────────────────────────────┘
                         │
                    CloudShell
                  (AWS-Managed Access)
```

---

## Key Design Decisions

### 1. Public Subnets (2)
- **Purpose**: Host the Classic LoadBalancer only
- **Security**: 
  - ACL restricts inbound to your IP only
  - No EC2 instances
  - No NAT Gateways
- **Traffic**: Port 80 (HTTP) from your IP → LoadBalancer

### 2. Private Subnets (2)
- **Purpose**: Host EKS cluster and worker nodes
- **Security**:
  - No direct internet access
  - No NAT Gateways needed
  - Pods pull images from ECR (same AWS account)
  - No inbound from internet
- **Traffic**: Internal only (LB → Pods)

### 3. Admin Access
- **Method**: AWS CloudShell
- **Why**: 
  - AWS-managed (no SSH keys needed)
  - Temporary credentials
  - Full access to private resources
  - Audit trail in CloudTrail
  - No bastion host needed

### 4. Network ACLs
- **Public Subnet ACL**:
  - Inbound: TCP port 80 from YOUR_IP/32
  - Outbound: TCP ephemeral ports (1024-65535) to private subnets
  
- **Private Subnet ACL**:
  - Inbound: TCP port 8080 from public subnets (10.0.0.0/26)
  - Outbound: All traffic (for pod communication)

---

## Security Benefits

| Aspect | Benefit |
|--------|---------|
| **Network Isolation** | EKS nodes completely isolated from internet |
| **Reduced Attack Surface** | No NAT Gateways, no bastion hosts |
| **Cost Reduction** | No NAT Gateway charges (~$32/month each) |
| **Simplified Management** | Fewer resources to manage and monitor |
| **Admin Access** | CloudShell provides secure, audited access |
| **IP Restriction** | Only your IP can access LoadBalancer |
| **No SSH Keys** | CloudShell eliminates SSH key management |

---

## Infrastructure Changes

### Removed (from current setup)
- ❌ NAT Gateways (2)
- ❌ Elastic IPs (2)
- ❌ Public route tables (simplified)
- ❌ Terraform-managed NLB/Target Groups

### Kept
- ✅ VPC (10.0.0.0/26)
- ✅ Public Subnets (2) - for LoadBalancer
- ✅ Private Subnets (2) - for EKS
- ✅ EKS Cluster
- ✅ Worker Nodes (2)
- ✅ Kubernetes-managed LoadBalancer (Classic)
- ✅ ECR Repository

### Added
- ✅ Network ACLs (public + private)
- ✅ Security Groups (refined)
- ✅ CloudShell documentation

---

## Terraform Changes Required

### 1. Remove NAT Gateways
```hcl
# DELETE: aws_nat_gateway resources
# DELETE: aws_eip resources for NAT
```

### 2. Simplify Route Tables
```hcl
# Public route table: Only for LoadBalancer (no internet route needed)
# Private route table: No routes (local only)
```

### 3. Add Network ACLs
```hcl
# Public subnet ACL: Restrict to YOUR_IP on port 80
# Private subnet ACL: Allow internal traffic only
```

### 4. Update Security Groups
```hcl
# EKS security group: Allow port 8080 from public subnets only
# Remove: Any rules allowing internet access
```

---

## Access Patterns

### Pattern 1: Public API Access
```
Your Computer (IP: X.X.X.X)
    ↓
ACL Check: Is source IP X.X.X.X? ✓
    ↓
LoadBalancer (Port 80)
    ↓
EKS Service (Port 8080)
    ↓
Microservice Pod
```

### Pattern 2: Admin Access (CloudShell)
```
AWS Console
    ↓
CloudShell (AWS-managed)
    ↓
Temporary AWS Credentials
    ↓
kubectl / aws cli
    ↓
Private Subnets (EKS)
```

---

## Implementation Steps

### Phase 1: Destroy Current Infrastructure
- [ ] Trigger Terraform destroy workflow
- [ ] Verify all resources deleted
- [ ] Confirm no orphaned resources

### Phase 2: Update Terraform Code
- [ ] Remove NAT Gateway resources
- [ ] Remove Elastic IP resources
- [ ] Simplify route tables
- [ ] Add Network ACLs
- [ ] Update security groups
- [ ] Add CloudShell documentation

### Phase 3: Rebuild Infrastructure
- [ ] Run Terraform apply
- [ ] Verify all resources created
- [ ] Confirm ACLs are correct
- [ ] Test LoadBalancer access

### Phase 4: Deploy Microservice
- [ ] Trigger deploy workflow
- [ ] Verify pods running
- [ ] Test API endpoints
- [ ] Confirm CloudShell access works

---

## Network Configuration Details

### VPC CIDR
- **Range**: 10.0.0.0/26 (64 IPs)
- **Usable**: 62 IPs (2 reserved)

### Subnet Allocation
```
Public Subnet 1:  10.0.0.0/28   (16 IPs)
Public Subnet 2:  10.0.0.16/28  (16 IPs)
Private Subnet 1: 10.0.0.32/28  (16 IPs)
Private Subnet 2: 10.0.0.48/28  (16 IPs)
```

### ACL Rules

**Public Subnet Inbound:**
```
Rule 100: Allow TCP port 80 from YOUR_IP/32
Rule 110: Allow TCP ephemeral (1024-65535) from 10.0.0.32/28
Rule 120: Allow TCP ephemeral (1024-65535) from 10.0.0.48/28
Rule 32767: Deny all (default)
```

**Public Subnet Outbound:**
```
Rule 100: Allow TCP ephemeral (1024-65535) to 10.0.0.32/28
Rule 110: Allow TCP ephemeral (1024-65535) to 10.0.0.48/28
Rule 32767: Deny all (default)
```

**Private Subnet Inbound:**
```
Rule 100: Allow TCP port 8080 from 10.0.0.0/28
Rule 110: Allow TCP port 8080 from 10.0.0.16/28
Rule 120: Allow all from 10.0.0.32/28 (pod-to-pod)
Rule 130: Allow all from 10.0.0.48/28 (pod-to-pod)
Rule 32767: Deny all (default)
```

**Private Subnet Outbound:**
```
Rule 100: Allow all to 10.0.0.0/26 (internal)
Rule 32767: Deny all (default)
```

---

## CloudShell Access Guide

### What is CloudShell?
- AWS-managed terminal in AWS Console
- Pre-configured with AWS CLI
- Temporary credentials (auto-rotated)
- No SSH keys needed
- Full audit trail in CloudTrail

### How to Use CloudShell

1. **Open CloudShell**
   - Go to AWS Console
   - Click CloudShell icon (top right)
   - Wait for terminal to load

2. **Access EKS**
   ```bash
   aws eks update-kubeconfig --region us-east-1 --name devops-aws-java-cluster
   kubectl get pods
   ```

3. **View Logs**
   ```bash
   kubectl logs -f deployment/microservice
   ```

4. **Scale Deployment**
   ```bash
   kubectl scale deployment microservice --replicas=3
   ```

5. **Port Forward (if needed)**
   ```bash
   kubectl port-forward svc/microservice 8080:80
   ```

### CloudShell Advantages
- ✅ No SSH key management
- ✅ Temporary credentials (auto-expire)
- ✅ Full AWS CLI access
- ✅ Pre-configured environment
- ✅ Audit trail in CloudTrail
- ✅ Works from any browser
- ✅ No bastion host needed

---

## Security Checklist

### Network Security
- [ ] NAT Gateways removed
- [ ] Public subnets have no EC2 instances
- [ ] Private subnets have no internet access
- [ ] ACLs restrict public subnet to your IP
- [ ] Security groups allow only necessary ports

### Access Control
- [ ] LoadBalancer only accessible from your IP
- [ ] EKS nodes only accessible from private subnets
- [ ] CloudShell is primary admin access method
- [ ] No SSH keys needed
- [ ] All access logged in CloudTrail

### Cost Optimization
- [ ] No NAT Gateway charges
- [ ] No unnecessary resources
- [ ] Minimal data transfer costs
- [ ] Estimated monthly cost: ~$150-200

### Monitoring
- [ ] CloudTrail logging enabled
- [ ] VPC Flow Logs enabled (optional)
- [ ] CloudWatch alarms configured
- [ ] Security group audit enabled

---

## Rollback Plan

If Option 1 doesn't work as expected:

1. **Destroy current infrastructure**
   ```bash
   terraform -chdir=terraform destroy -auto-approve
   ```

2. **Revert Terraform code**
   ```bash
   git revert <commit-hash>
   ```

3. **Rebuild with previous architecture**
   ```bash
   terraform -chdir=terraform apply -auto-approve
   ```

---

## Cost Comparison

### Current Setup (with NAT Gateways)
- NAT Gateway: $32/month × 2 = $64/month
- Data processing: ~$10/month
- **Total**: ~$175-200/month

### Option 1 (Simplified)
- NAT Gateway: $0/month (removed)
- Data processing: ~$5/month
- **Total**: ~$150-170/month

**Savings**: ~$25-30/month (15% reduction)

---

## Next Steps

1. ✅ Destroy current infrastructure (in progress)
2. ⏳ Update Terraform code for Option 1
3. ⏳ Rebuild infrastructure
4. ⏳ Deploy microservice
5. ⏳ Test all access patterns
6. ⏳ Document final architecture

---

**Last Updated:** February 5, 2026  
**Status:** Awaiting infrastructure destruction completion
