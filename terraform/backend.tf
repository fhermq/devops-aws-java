# S3 Backend Configuration for Terraform State
# This stores the Terraform state file in S3 instead of locally
# Prevents state loss and enables team collaboration

terraform {
  backend "s3" {
    bucket         = "devops-aws-java-terraform-state"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
