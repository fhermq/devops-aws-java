# EKS Cluster
resource "aws_eks_cluster" "main" {
  name            = var.eks_cluster_name
  role_arn        = aws_iam_role.eks_cluster_role.arn
  version         = var.kubernetes_version
  
  vpc_config {
    subnet_ids              = aws_subnet.private[*].id
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller,
  ]

  tags = {
    Name        = var.eks_cluster_name
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# EKS Cluster IAM Role
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.eks_cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name      = "${var.eks_cluster_name}-cluster-role"
    ManagedBy = "Terraform"
  }
}

# Attach required policies to cluster role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster_role.name
}

# EKS Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.eks_cluster_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = aws_subnet.private[*].id
  version         = var.kubernetes_version

  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  instance_types = var.node_instance_types

  tags = {
    Name        = "${var.eks_cluster_name}-node-group"
    Environment = "production"
    ManagedBy   = "Terraform"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy,
  ]
}

# EKS Node IAM Role
resource "aws_iam_role" "eks_node_role" {
  name = "${var.eks_cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name      = "${var.eks_cluster_name}-node-role"
    ManagedBy = "Terraform"
  }
}

# Attach required policies to node role
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

# Output cluster details
output "eks_cluster_name" {
  description = "EKS Cluster Name"
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  description = "EKS Cluster Endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "eks_cluster_version" {
  description = "EKS Cluster Version"
  value       = aws_eks_cluster.main.version
}

output "eks_cluster_arn" {
  description = "EKS Cluster ARN"
  value       = aws_eks_cluster.main.arn
}

# AWS Load Balancer Controller via Helm (using local-exec to work around auth issues)
resource "null_resource" "load_balancer_controller" {
  provisioner "local-exec" {
    command = <<-EOT
      set -e
      echo "Installing AWS Load Balancer Controller..."
      
      # Update kubeconfig
      aws eks update-kubeconfig --region us-east-1 --name devops-aws-java-cluster
      
      # Add Helm repo
      helm repo add eks https://aws.github.io/eks-charts || true
      helm repo update
      
      # Install load balancer controller
      helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
        -n kube-system \
        --set clusterName=devops-aws-java-cluster \
        --set serviceAccount.roleArn=arn:aws:iam::444625565163:role/devops-aws-java-cluster-load-balancer-controller-role \
        --wait=false || true
      
      echo "AWS Load Balancer Controller installation completed"
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      set -e
      echo "Uninstalling AWS Load Balancer Controller..."
      
      # Update kubeconfig
      aws eks update-kubeconfig --region us-east-1 --name devops-aws-java-cluster || true
      
      # Uninstall load balancer controller
      helm uninstall aws-load-balancer-controller -n kube-system || echo "Load balancer controller not found, skipping"
      
      echo "AWS Load Balancer Controller uninstalled successfully"
    EOT
  }

  depends_on = [
    aws_eks_cluster.main,
    aws_iam_role_policy.aws_load_balancer_controller
  ]
}

output "load_balancer_controller_status" {
  description = "AWS Load Balancer Controller Installation Status"
  value       = "Installed via Helm"
}


# Configure kubectl access for local user
resource "null_resource" "configure_kubectl_user_access" {
  provisioner "local-exec" {
    command = <<-EOT
      set -e
      echo "Configuring kubectl access for user..."
      
      # Update kubeconfig
      aws eks update-kubeconfig --region us-east-1 --name devops-aws-java-cluster
      
      # Get current auth config
      kubectl get configmap aws-auth -n kube-system -o yaml > /tmp/aws-auth.yaml
      
      # Check if user already exists
      if grep -q "cli_pixan" /tmp/aws-auth.yaml; then
        echo "User cli_pixan already in auth config map"
      else
        echo "Adding user cli_pixan to auth config map..."
        # Add user to mapUsers section
        cat >> /tmp/aws-auth.yaml << 'USEREOF'
  - rolearn: arn:aws:iam::444625565163:user/cli_pixan
    username: cli_pixan
    groups:
      - system:masters
USEREOF
        kubectl apply -f /tmp/aws-auth.yaml
        echo "User cli_pixan added successfully"
      fi
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      set -e
      echo "Removing kubectl access for user..."
      
      # Update kubeconfig
      aws eks update-kubeconfig --region us-east-1 --name devops-aws-java-cluster || true
      
      # Get current auth config
      kubectl get configmap aws-auth -n kube-system -o yaml > /tmp/aws-auth.yaml || true
      
      # Remove user from mapUsers section
      if grep -q "cli_pixan" /tmp/aws-auth.yaml; then
        echo "Removing user cli_pixan from auth config map..."
        # Use sed to remove the user block (3 lines: rolearn, username, groups)
        sed -i '' '/- rolearn: arn:aws:iam::444625565163:user\/cli_pixan/,/- system:masters/d' /tmp/aws-auth.yaml
        kubectl apply -f /tmp/aws-auth.yaml || true
        echo "User cli_pixan removed successfully"
      else
        echo "User cli_pixan not found in auth config map"
      fi
    EOT
  }

  depends_on = [
    aws_eks_cluster.main
  ]
}

output "kubectl_user_configured" {
  description = "Status of kubectl user configuration"
  value       = "User cli_pixan configured for cluster access"
}
