# Network Load Balancer - Managed by Kubernetes
# 
# The NLB is automatically created by the AWS Load Balancer Controller
# when a Kubernetes service with type: LoadBalancer is deployed.
#
# This file is kept for reference and documentation purposes.
# No Terraform-managed resources here - Kubernetes handles the lifecycle.
#
# To get the NLB DNS name after deployment:
#   kubectl get svc microservice -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
#
# Architecture:
# - Public Subnets: NLB receives traffic (restricted by Network ACL to user IP)
# - Private Subnets: EKS nodes run pods
# - Traffic flow: User IP → NLB → EKS Nodes → Pods (port 8080)
#
# The AWS Load Balancer Controller automatically:
# - Creates the NLB in public subnets
# - Registers EKS nodes as targets
# - Configures health checks
# - Manages security groups
# - Handles lifecycle (create/delete with service)
