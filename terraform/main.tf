terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

resource "aws_vpc" "taskforge_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.taskforge_vpc.id
  tags = {
    Name = "main-gw"
  }
}

#Get Availability Zones
data "aws_availability_zones" "available" {
  state = "available"
}



#Public Subnet
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.taskforge_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "taskforge-public-a"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.taskforge_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "taskforge-public-b"
    "kubernetes.io/role/elb" = "1"
  }
}

# Private Subnet
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.taskforge_vpc.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "taskforge-private-a"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.taskforge_vpc.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "taskforge-private-b"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

#Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.taskforge_vpc.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "public-rt"
  }
}

# Associate Route Table with Public Subnet
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

#Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.taskforge_vpc.id

  tags = {
    Name = "taskforge-private-rt"
  }
}

# Add a route to the NAT Gateway in the private route table
resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.taskforge.id
}

# Associate Route Table with Private Subnet
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "taskforge-nat-eip"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "taskforge_nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name = "taskforge-nat-gateway"
  }

  depends_on = [
    aws_internet_gateway.gw
  ]
}


# Security Group for public-facing resources
resource "aws_security_group" "public" {
  name        = "taskforge-public-sg"
  description = "Security group for public-facing resources"
  vpc_id      = aws_vpc.taskforge_vpc.id

  # HTTP
  ingress {
    description = "HTTP from the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    description = "HTTPS from the internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow outbound traffic
  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "taskforge-public-sg"
  }
}

# Security Group for application resources
resource "aws_security_group" "app" {
  name        = "taskforge-app-sg"
  description = "Security group for TaskForge application resources"
  vpc_id      = aws_vpc.taskforge_vpc.id

  # Allow application traffic from the public security group
  ingress {
    description     = "Application traffic from public resources"
    from_port       = 4000
    to_port         = 4000
    protocol        = "tcp"
    security_groups = [aws_security_group.public.id]
  }

  # Allow outbound traffic
  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "taskforge-app-sg"
  }
}
# IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster" {
  name = "taskforge-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "eks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "taskforge-eks-cluster-role"
  }
}

# Attach the AmazonEKSClusterPolicy to the IAM Role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Create the EKS Cluster
resource "aws_eks_cluster" "taskforge" {
  name     = "taskforge"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.36"

  vpc_config {
    subnet_ids = [
      aws_subnet.private_a.id,
      aws_subnet.private_b.id
    ]

    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]

  tags = {
    Name = "taskforge-eks"
  }
}

# IAM Role for EKS Node Group
resource "aws_iam_role" "eks_nodes" {
  name = "taskforge-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "taskforge-eks-node-role"
  }
}

# Attach the AmazonEKSWorkerNodePolicy and AmazonEC2ContainerRegistryPullOnly policies to the IAM Role
resource "aws_iam_role_policy_attachment" "eks_worker_node" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# Allow EKS worker nodes to pull images from ECR
resource "aws_iam_role_policy_attachment" "eks_ecr_pull" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
}

# Create the EKS Node Group
resource "aws_eks_node_group" "taskforge" {
  cluster_name = aws_eks_cluster.taskforge.name
  node_group_name = "taskforge-workers"
  node_role_arn = aws_iam_role.eks_nodes.arn

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  instance_types = ["t3.small"]

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 3
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node,
    aws_iam_role_policy_attachment.eks_ecr_pull
  ]

  tags = {
    Name = "taskforge-worker"
  }
}