# Phase 1: Backend Infrastructure
# S3 bucket and DynamoDB table for Terraform state management

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "devops-aws-java"
      Environment = "production"
      ManagedBy   = "Terraform"
    }
  }
}
