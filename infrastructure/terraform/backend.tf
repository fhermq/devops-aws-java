# S3 Backend Configuration for Terraform State
# This stores the Terraform state file in S3 instead of locally
# Prevents state loss and enables team collaboration
# 
# Note: Backend configuration uses hardcoded values that match phase-1-backend outputs
# These values are set up by: terraform/phase-1-backend/

terraform {
  backend "s3" {
    bucket         = "devops-aws-java-terraform-state"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
