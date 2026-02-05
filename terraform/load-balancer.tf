# This file is kept for reference but the NLB is now managed by Kubernetes
# When service type is LoadBalancer, EKS automatically creates an NLB
# and registers targets via the AWS Load Balancer Controller

# Note: The Kubernetes service will create its own NLB
# This Terraform-managed NLB can be removed or kept as a reference

output "load_balancer_dns" {
  description = "DNS name of the load balancer (managed by Kubernetes)"
  value       = "Check kubectl get svc microservice for LoadBalancer endpoint"
}
