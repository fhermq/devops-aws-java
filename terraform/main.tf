terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.main.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.main.token
  }
}

# Get EKS cluster auth token
data "aws_eks_cluster_auth" "main" {
  name = aws_eks_cluster.main.name
}

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

# Safeguard: Prevent deployment to wrong account
resource "null_resource" "account_validation" {
  lifecycle {
    precondition {
      condition     = data.aws_caller_identity.current.account_id == var.aws_account_id
      error_message = "ERROR: Attempting to deploy to account ${data.aws_caller_identity.current.account_id}, but terraform.tfvars specifies account ${var.aws_account_id}. Aborting to prevent accidental deployment to wrong account."
    }
  }
}
