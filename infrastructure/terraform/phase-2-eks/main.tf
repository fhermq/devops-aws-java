terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Backend configuration uses hardcoded values that match phase-1-backend outputs
  # These values are set up by: terraform/phase-1-backend/
  backend "s3" {
    bucket         = "devops-aws-java-terraform-state"
    key            = "phase-2-eks/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
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
