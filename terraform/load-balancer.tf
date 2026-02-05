# Security Group for NLB
resource "aws_security_group" "nlb" {
  name        = "${var.eks_cluster_name}-nlb-sg"
  description = "Security group for NLB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${var.eks_cluster_name}-nlb-sg"
    ManagedBy = "Terraform"
  }
}

# Network Load Balancer for microservice
resource "aws_lb" "microservice" {
  name               = "${var.eks_cluster_name}-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = aws_subnet.public[*].id
  security_groups    = [aws_security_group.nlb.id]

  tags = {
    Name      = "${var.eks_cluster_name}-nlb"
    ManagedBy = "Terraform"
  }
}

# Target Group
resource "aws_lb_target_group" "microservice" {
  name        = "${var.eks_cluster_name}-tg"
  port        = 8080
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
  }

  tags = {
    Name      = "${var.eks_cluster_name}-tg"
    ManagedBy = "Terraform"
  }
}

# Listener
resource "aws_lb_listener" "microservice" {
  load_balancer_arn = aws_lb.microservice.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.microservice.arn
  }
}

# Outputs
output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = aws_lb.microservice.dns_name
}

output "load_balancer_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.microservice.arn
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.microservice.arn
}
