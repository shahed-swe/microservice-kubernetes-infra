#!/bin/bash

# Master startup script for CDN Infrastructure
# Starts all services: Docker + Kubernetes

set -e

echo "Starting CDN Infrastructure..."
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() {
    echo -e "${GREEN}[STEP]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
print_step "Checking prerequisites..."

if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed"
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed"
    exit 1
fi

echo "Docker: OK"
echo "kubectl: OK"
echo ""

# Step 1: Start Docker services
print_step "Starting Docker services..."
cd docker
docker-compose up -d
cd ..

echo "Waiting for services to be healthy..."
sleep 10

# Verify Docker services
if docker exec postgres-global pg_isready -U cdn_admin_global &> /dev/null; then
    echo "PostgreSQL Global: OK"
else
    print_error "PostgreSQL Global failed to start"
    exit 1
fi

if docker exec postgres-regional pg_isready -U cdn_admin_regional &> /dev/null; then
    echo "PostgreSQL Regional: OK"
else
    print_error "PostgreSQL Regional failed to start"
    exit 1
fi

if curl -f http://localhost:9000/minio/health/live &> /dev/null; then
    echo "MinIO: OK"
else
    print_error "MinIO failed to start"
    exit 1
fi

echo ""

# Step 2: Check Kubernetes cluster
print_step "Checking Kubernetes cluster..."

if ! kubectl cluster-info &> /dev/null; then
    print_error "Kubernetes cluster is not accessible"
    print_info "Make sure your Kubernetes cluster is running (Docker Desktop, Minikube, etc.)"
    exit 1
fi

echo "Kubernetes cluster: OK"
echo ""

# Step 3: Deploy to Kubernetes
print_step "Deploying to Kubernetes..."

# Create namespaces and configuration
kubectl apply -f kubernetes/01-namespaces-and-config.yaml &> /dev/null
echo "Namespaces and configuration deployed"

# Deploy test applications
kubectl apply -f kubernetes/02-test-applications.yaml &> /dev/null
echo "Test applications deployed"

# Create monitoring namespace
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f - &> /dev/null

# Deploy monitoring services
kubectl apply -f kubernetes/03-monitoring.yaml &> /dev/null
echo "Monitoring services deployed"

# Deploy monitoring deployments (Prometheus and Grafana)
kubectl apply -f kubernetes/04-monitoring-deployments.yaml &> /dev/null
echo "Prometheus and Grafana deployed"

echo ""

# Wait for Kubernetes resources to be ready
print_step "Waiting for Kubernetes pods to start..."
sleep 10

# Check pod status
PODS_READY=$(kubectl get pods -n cdn-global -q 2>/dev/null | wc -l)
echo "Global namespace pods: $PODS_READY"

MONITORING_PODS=$(kubectl get pods -n monitoring -q 2>/dev/null | wc -l)
echo "Monitoring namespace pods: $MONITORING_PODS"

echo ""

# Summary
print_step "CDN Infrastructure is starting up!"
echo ""
echo "Docker Services:"
echo "  PostgreSQL Global:   localhost:5432"
echo "  PostgreSQL Regional: localhost:5433"
echo "  MinIO Console:       http://localhost:9001"
echo "  MinIO API:           http://localhost:9000"
echo "  pgAdmin:             http://localhost:5050"
echo ""
echo "Kubernetes Services:"
echo "  Global Nginx:        kubectl port-forward -n cdn-global svc/nginx-test-service 8080:80"
echo "  Regional Nginx:      kubectl port-forward -n cdn-regional svc/nginx-test-service 8081:80"
echo "  Grafana:             http://localhost:3000 (admin/admin123)"
echo "  Prometheus:          kubectl port-forward -n monitoring svc/prometheus 9090:9090"
echo ""

print_info "Run './test-connectivity.sh' to verify all services are working"
echo ""
