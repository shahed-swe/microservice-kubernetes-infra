# Main Terraform configuration for AWS deployment
# This configuration is parameterized to work with environment variables

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment to use S3 backend for state management
  # backend "s3" {
  #   bucket         = "cdn-terraform-state"
  #   key            = "infrastructure/terraform.tfstate"
  #   region         = var.aws_region
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "CDN"
      ManagedBy   = "Terraform"
    }
  }
}

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

# Create VPC
resource "aws_vpc" "cdn_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.environment}-cdn-vpc"
  }
}

# Create subnets
resource "aws_subnet" "public" {
  count                   = 3
  vpc_id                  = aws_vpc.cdn_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 2, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-public-subnet-${count.index + 1}"
  }
}

# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Internet Gateway
resource "aws_internet_gateway" "cdn_igw" {
  vpc_id = aws_vpc.cdn_vpc.id

  tags = {
    Name = "${var.environment}-igw"
  }
}

# Route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.cdn_vpc.id

  route {
    cidr_block      = "0.0.0.0/0"
    gateway_id      = aws_internet_gateway.cdn_igw.id
  }

  tags = {
    Name = "${var.environment}-public-rt"
  }
}

# Route table associations
resource "aws_route_table_association" "public" {
  count          = 3
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Security group for RDS
resource "aws_security_group" "rds" {
  name        = "${var.environment}-rds-sg"
  description = "Security group for RDS databases"
  vpc_id      = aws_vpc.cdn_vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-rds-sg"
  }
}

# Security group for EKS nodes
resource "aws_security_group" "eks_nodes" {
  name        = "${var.environment}-eks-nodes-sg"
  description = "Security group for EKS nodes"
  vpc_id      = aws_vpc.cdn_vpc.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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
    Name = "${var.environment}-eks-nodes-sg"
  }
}

# DB Subnet Group
resource "aws_db_subnet_group" "cdn" {
  name       = "${var.environment}-cdn-db-subnet-group"
  subnet_ids = aws_subnet.public[*].id

  tags = {
    Name = "${var.environment}-cdn-db-subnet-group"
  }
}

# Global RDS Instance
resource "aws_db_instance" "global" {
  identifier              = "${var.environment}-cdn-global-postgres"
  engine                  = "postgres"
  engine_version          = var.postgres_version
  instance_class          = var.rds_instance_class
  allocated_storage       = var.rds_allocated_storage
  storage_encrypted       = true
  db_name                 = "cdn_global"
  username                = var.db_global_username
  password                = var.db_global_password
  db_subnet_group_name    = aws_db_subnet_group.cdn.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  multi_az                = true
  publicly_accessible     = false
  skip_final_snapshot     = var.environment == "development" ? true : false
  backup_retention_period = var.backup_retention_days
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"

  tags = {
    Name = "${var.environment}-cdn-global-postgres"
  }
}

# Regional RDS Instance
resource "aws_db_instance" "regional" {
  identifier              = "${var.environment}-cdn-regional-uswest-postgres"
  engine                  = "postgres"
  engine_version          = var.postgres_version
  instance_class          = var.rds_instance_class
  allocated_storage       = var.rds_allocated_storage
  storage_encrypted       = true
  db_name                 = "cdn_regional_uswest"
  username                = var.db_regional_username
  password                = var.db_regional_password
  db_subnet_group_name    = aws_db_subnet_group.cdn.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  multi_az                = true
  publicly_accessible     = false
  skip_final_snapshot     = var.environment == "development" ? true : false
  backup_retention_period = var.backup_retention_days
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"

  tags = {
    Name = "${var.environment}-cdn-regional-uswest-postgres"
  }
}

# S3 Bucket for config bundles
resource "aws_s3_bucket" "config_bundles" {
  bucket = "${var.environment}-cdn-config-bundles-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "${var.environment}-cdn-config-bundles"
  }
}

# Enable versioning
resource "aws_s3_bucket_versioning" "config_bundles" {
  bucket = aws_s3_bucket.config_bundles.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "config_bundles" {
  bucket = aws_s3_bucket.config_bundles.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Lifecycle policy to delete old versions
resource "aws_s3_bucket_lifecycle_configuration" "config_bundles" {
  bucket = aws_s3_bucket.config_bundles.id

  rule {
    id     = "delete-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "config_bundles" {
  bucket = aws_s3_bucket.config_bundles.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM role for EKS
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.environment}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# IAM role for EKS nodes
resource "aws_iam_role" "eks_node_role" {
  name = "${var.environment}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_registry_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Instance profile for EKS nodes
resource "aws_iam_instance_profile" "eks_node_profile" {
  name = "${var.environment}-eks-node-profile"
  role = aws_iam_role.eks_node_role.name
}

# Outputs
output "global_rds_endpoint" {
  value       = aws_db_instance.global.endpoint
  description = "Global RDS database endpoint"
}

output "regional_rds_endpoint" {
  value       = aws_db_instance.regional.endpoint
  description = "Regional RDS database endpoint"
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.config_bundles.id
  description = "S3 bucket for configuration bundles"
}

output "vpc_id" {
  value       = aws_vpc.cdn_vpc.id
  description = "VPC ID"
}
