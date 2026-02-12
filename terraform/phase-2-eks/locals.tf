locals {
  common_tags = {
    ManagedBy   = "Terraform"
    Environment = "production"
  }

  cluster_name = var.eks_cluster_name
  vpc_cidr     = var.vpc_cidr
}
