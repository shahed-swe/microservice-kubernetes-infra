# Development environment configuration
# Usage: terraform apply -var-file=terraform-dev.tfvars

aws_region              = "us-west-2"
environment             = "development"
vpc_cidr                = "10.0.0.0/16"
postgres_version        = "15.3"
rds_instance_class      = "db.t3.medium"
rds_allocated_storage   = 100
backup_retention_days   = 7
eks_cluster_version     = "1.28"
eks_node_instance_type  = "t3.medium"
eks_desired_size        = 2
eks_min_size            = 1
eks_max_size            = 3
