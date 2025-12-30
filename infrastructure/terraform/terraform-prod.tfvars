# Production environment configuration
# Usage: terraform apply -var-file=terraform-prod.tfvars

aws_region              = "us-west-2"
environment             = "production"
vpc_cidr                = "10.0.0.0/16"
postgres_version        = "15.3"
rds_instance_class      = "db.t3.xlarge"
rds_allocated_storage   = 500
backup_retention_days   = 30
eks_cluster_version     = "1.28"
eks_node_instance_type  = "t3.xlarge"
eks_desired_size        = 5
eks_min_size            = 3
eks_max_size            = 10
