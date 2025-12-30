# CDN Infrastructure Setup Guide

This directory contains everything needed to set up the CDN infrastructure locally for development and in the cloud (AWS/GCP/Azure) for production.

## 📁 Directory Structure

```
infrastructure/
├── docker/                    # Local Docker setup (PostgreSQL, MinIO, pgAdmin)
│   ├── docker-compose.yml    # Docker Compose configuration
│   └── init-scripts/         # Database initialization SQL scripts
├── kubernetes/               # Kubernetes manifests (works with local k8s)
│   ├── 01-namespaces-and-config.yaml
│   ├── 02-test-applications.yaml
│   └── 03-monitoring.yaml
├── terraform/               # Cloud infrastructure-as-code (AWS)
│   ├── aws-main.tf
│   ├── variables.tf
│   ├── terraform-dev.tfvars
│   └── terraform-prod.tfvars
├── helm/                    # Helm charts (to be populated)
├── setup-local.sh          # Script to start local infrastructure
├── deploy-to-k8s.sh        # Script to deploy to Kubernetes
├── test-connectivity.sh    # Script to test connections
└── cleanup.sh              # Script to clean up resources
```

## 🚀 Quick Start (Local Development)

### Prerequisites
- Docker & Docker Compose installed
- kubectl configured (for Kubernetes deployment)
- PostgreSQL client tools (optional, for direct DB access)

### Step 1: Start Local Infrastructure

```bash
chmod +x setup-local.sh
./setup-local.sh
```

This will:
- ✅ Start PostgreSQL Global database
- ✅ Start PostgreSQL Regional database  
- ✅ Start MinIO (S3-compatible object storage)
- ✅ Start pgAdmin (database management UI)

**Services will be available at:**
- PostgreSQL Global: `localhost:5432` (User: `cdn_admin_global`)
- PostgreSQL Regional: `localhost:5433` (User: `cdn_admin_regional`)
- MinIO Console: http://localhost:9001
- MinIO API: http://localhost:9000
- pgAdmin: http://localhost:5050

### Step 2: Test Connectivity

```bash
chmod +x test-connectivity.sh
./test-connectivity.sh
```

This verifies all services are running and accessible.

### Step 3: Deploy to Kubernetes

```bash
chmod +x deploy-to-k8s.sh
./deploy-to-k8s.sh
```

This deploys test applications to your local Kubernetes cluster.

### Step 4: Access Services

```bash
# Port forward to test application
kubectl port-forward -n cdn-global svc/nginx-test-service 8080:80

# Access at http://localhost:8080
```

## 🐳 Docker Services Details

### PostgreSQL Global
- **Container**: `postgres-global`
- **Port**: 5432
- **Database**: `cdn_global`
- **User**: `cdn_admin_global`
- **Password**: `ChangeMe123!Global` (set in docker-compose.yml)
- **Data**: Persisted in volume `postgres_global_data`

**Initial Tables Created:**
- `global.clusters` - Cluster metadata
- `global.config_bundles` - Configuration bundles
- `global.deployments` - Deployment tracking

### PostgreSQL Regional
- **Container**: `postgres-regional`
- **Port**: 5433
- **Database**: `cdn_regional_uswest`
- **User**: `cdn_admin_regional`
- **Password**: `ChangeMe123!Regional` (set in docker-compose.yml)
- **Data**: Persisted in volume `postgres_regional_data`

**Initial Tables Created:**
- `regional.edge_nodes` - Edge server information
- `regional.content_distribution` - Content distribution tracking
- `regional.metrics` - Performance metrics

### MinIO
- **Container**: `minio-server`
- **Console Port**: 9001
- **API Port**: 9000
- **Access Key**: `minioadmin`
- **Secret Key**: `minioadmin123`
- **Data**: Persisted in volume `minio_data`

**Create bucket for config storage:**
```bash
# Using MinIO console at http://localhost:9001
# Or via CLI (mc):
# mc alias set local http://localhost:9000 minioadmin minioadmin123
# mc mb local/cdn-config-bundles
```

### pgAdmin
- **URL**: http://localhost:5050
- **Email**: admin@example.com
- **Password**: admin123

To add PostgreSQL servers in pgAdmin:
1. Login to http://localhost:5050
2. Register → Server
3. Connection details:
   - **Global**: hostname=postgres-global, port=5432, username=cdn_admin_global
   - **Regional**: hostname=postgres-regional, port=5433, username=cdn_admin_regional

## ☸️ Kubernetes Deployment

### Namespaces Created
- `cdn-global` - Global control plane services
- `cdn-regional` - Regional control plane services

### Deployed Applications
- **Nginx Test** (2 replicas in each namespace)
  - LoadBalancer service for external access
  - Health checks configured

### Monitoring Setup
- Prometheus configuration for cluster metrics
- Prometheus scrapes:
  - Kubernetes API servers
  - Node metrics
  - Pod metrics

### Accessing Services

```bash
# List all services
kubectl get svc -A

# Port forward to specific service
kubectl port-forward -n cdn-global svc/nginx-test-service 8080:80

# View pod logs
kubectl logs -n cdn-global <pod-name>

# Describe deployment
kubectl describe deployment -n cdn-global
```

## ☁️ Cloud Deployment (AWS)

### Prerequisites
- Terraform installed (v1.0+)
- AWS CLI configured with credentials
- AWS account with appropriate permissions

### Configuration Files
- `terraform-dev.tfvars` - Development environment settings
- `terraform-prod.tfvars` - Production environment settings
- `variables.tf` - Variable definitions
- `aws-main.tf` - Main infrastructure code

### Resources Created
- **VPC & Networking**: VPC with 3 public subnets across AZs
- **RDS PostgreSQL**: 2 instances (Global & Regional) with Multi-AZ
- **S3 Bucket**: For configuration bundles with versioning
- **Security Groups**: For RDS and EKS access
- **IAM Roles**: For EKS cluster and node access

### Deployment Steps

```bash
cd terraform

# Initialize Terraform
terraform init

# Plan deployment (development)
terraform plan -var-file=terraform-dev.tfvars -out=tfplan

# Apply deployment
terraform apply tfplan

# Get outputs
terraform output

# For production:
# terraform plan -var-file=terraform-prod.tfvars -out=tfplan
# terraform apply tfplan
```

### Customization
Edit `terraform-dev.tfvars` or `terraform-prod.tfvars` to customize:
- AWS region
- Database instance class and size
- VPC CIDR blocks
- Backup retention periods
- EKS cluster configuration

### Environment Variables
You can also use environment variables instead of tfvars:

```bash
export TF_VAR_db_global_password="YourSecurePassword123!"
export TF_VAR_db_regional_password="YourSecurePassword456!"
terraform apply
```

### Outputs
After successful deployment, get connection strings:

```bash
terraform output global_rds_endpoint
terraform output regional_rds_endpoint
terraform output s3_bucket_name
```

## 🔐 Secrets Management

### Local Development
- Store credentials in `.env` file (git-ignored)
- Load via: `source .env` or docker-compose environment variables

### Cloud Deployment
- Use AWS Secrets Manager
- Use Kubernetes Secrets for EKS
- Never commit credentials to git

## 📊 Monitoring & Logs

### Docker Logs
```bash
docker-compose -f docker/docker-compose.yml logs -f postgres-global
docker-compose -f docker/docker-compose.yml logs -f minio
```

### Kubernetes Logs
```bash
kubectl logs -n cdn-global -f deployment/nginx-test-global
kubectl logs -n cdn-regional -f deployment/nginx-test-regional
```

### Health Checks

**PostgreSQL:**
```bash
PGPASSWORD=ChangeMe123!Global psql -h localhost -p 5432 -U cdn_admin_global -d cdn_global -c "SELECT version();"
```

**MinIO:**
```bash
curl http://localhost:9000/minio/health/live
```

## 🧹 Cleanup

### Local Infrastructure
```bash
./cleanup.sh
```

This removes:
- All Docker containers
- All Docker volumes (persistent data)
- Kubernetes namespaces and resources

### Cloud Infrastructure
```bash
cd terraform
terraform destroy -var-file=terraform-dev.tfvars
```

## 📝 Database Initialization

The databases are initialized with sample schemas:

### Global Schema
```sql
CREATE TABLE global.clusters (...)
CREATE TABLE global.config_bundles (...)
CREATE TABLE global.deployments (...)
```

### Regional Schema
```sql
CREATE TABLE regional.edge_nodes (...)
CREATE TABLE regional.content_distribution (...)
CREATE TABLE regional.metrics (...)
```

To add more tables or modify schema, edit:
- `docker/init-scripts/global.sql`
- `docker/init-scripts/regional.sql`

Changes apply when containers are restarted.

## 🚀 Next Steps

1. **Local Testing**
   - Run setup-local.sh
   - Test database connections
   - Deploy test apps to Kubernetes

2. **Development**
   - Add your application containers
   - Update Kubernetes manifests
   - Add monitoring dashboards

3. **Cloud Migration**
   - Update Terraform variables
   - Run terraform plan/apply
   - Migrate data from local to cloud
   - Update Kubernetes kubeconfig

4. **Production Ready**
   - Set strong database passwords
   - Enable encryption at rest
   - Configure backup policies
   - Set up automated monitoring
   - Implement disaster recovery

## 🆘 Troubleshooting

### Docker containers won't start
```bash
# Check Docker is running
docker ps

# View logs
docker-compose -f docker/docker-compose.yml logs

# Rebuild containers
docker-compose -f docker/docker-compose.yml down -v
docker-compose -f docker/docker-compose.yml up -d
```

### Kubernetes resources not deploying
```bash
# Check cluster connectivity
kubectl cluster-info

# Check namespace creation
kubectl get namespaces

# View deployment status
kubectl describe deployment -n cdn-global

# View pod events
kubectl describe pod -n cdn-global <pod-name>
```

### Database connection issues
```bash
# Test PostgreSQL Global
pg_isready -h localhost -p 5432 -U cdn_admin_global

# Test PostgreSQL Regional
pg_isready -h localhost -p 5433 -U cdn_admin_regional

# Check running containers
docker ps
```

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [MinIO Documentation](https://min.io/docs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Helm Documentation](https://helm.sh/docs/)
