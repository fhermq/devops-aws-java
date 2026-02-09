# VPC Endpoints for private cluster - allows nodes to reach AWS services without internet

# EC2 VPC Endpoint
resource "aws_vpc_endpoint" "ec2" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ec2"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name      = "${var.eks_cluster_name}-ec2-endpoint"
    ManagedBy = "Terraform"
  }
}

# ECR API VPC Endpoint
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name      = "${var.eks_cluster_name}-ecr-api-endpoint"
    ManagedBy = "Terraform"
  }
}

# ECR DKR VPC Endpoint (for pulling images)
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name      = "${var.eks_cluster_name}-ecr-dkr-endpoint"
    ManagedBy = "Terraform"
  }
}

# S3 VPC Endpoint (Gateway type - no security group needed)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = {
    Name      = "${var.eks_cluster_name}-s3-endpoint"
    ManagedBy = "Terraform"
  }
}

# STS VPC Endpoint (for IAM authentication)
resource "aws_vpc_endpoint" "sts" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.sts"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name      = "${var.eks_cluster_name}-sts-endpoint"
    ManagedBy = "Terraform"
  }
}

# Security group for VPC Endpoints
resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.eks_cluster_name}-vpc-endpoints-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.main.id

  # Allow HTTPS from VPC
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${var.eks_cluster_name}-vpc-endpoints-sg"
    ManagedBy = "Terraform"
  }
}
