# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.eks_cluster_name}-vpc"
    ManagedBy   = "Terraform"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name      = "${var.eks_cluster_name}-igw"
    ManagedBy = "Terraform"
  }
}

# Public Subnets (for LoadBalancer only - no internet access needed)
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 2, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name                                           = "${var.eks_cluster_name}-public-${count.index + 1}"
    "kubernetes.io/role/elb"                       = "1"
    ManagedBy                                      = "Terraform"
  }
}

# Private Subnets (for EKS nodes - no internet access)
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 2, count.index + 2)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name                                           = "${var.eks_cluster_name}-private-${count.index + 1}"
    "kubernetes.io/role/internal-elb"             = "1"
    ManagedBy                                      = "Terraform"
  }
}

# Public Route Table (local only)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name      = "${var.eks_cluster_name}-public-rt"
    ManagedBy = "Terraform"
  }
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Route Table (local only)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name      = "${var.eks_cluster_name}-private-rt"
    ManagedBy = "Terraform"
  }
}

# Associate private subnets with private route table
resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Output VPC details
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "Public Subnet IDs (for LoadBalancer)"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private Subnet IDs (for EKS nodes)"
  value       = aws_subnet.private[*].id
}
