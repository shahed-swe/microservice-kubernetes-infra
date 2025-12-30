#!/bin/bash

# Deploy infrastructure to local Kubernetes cluster
# Prerequisites: kubectl must be configured and pointing to your local cluster

set -e

echo "Deploying CDN Infrastructure to Kubernetes..."
echo ""

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "[FAILED] kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if cluster is accessible
echo "Checking Kubernetes cluster connectivity..."
if ! kubectl cluster-info &> /dev/null; then
    echo "[FAILED] Cannot connect to Kubernetes cluster. Please configure kubectl."
    exit 1
fi

echo "[OK] Kubernetes cluster is accessible"
echo ""

# Apply manifests
MANIFEST_DIR="$(dirname "$0")/kubernetes"

echo "Applying Kubernetes manifests..."

# Create namespaces and config
echo "  Step 1: Creating namespaces and configuration..."
kubectl apply -f "$MANIFEST_DIR/01-namespaces-and-config.yaml"

# Deploy test applications
echo "  Step 2: Deploying test applications..."
kubectl apply -f "$MANIFEST_DIR/02-test-applications.yaml"

# Create monitoring namespace
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f - &> /dev/null

# Deploy monitoring services and config
echo "  Step 3: Creating monitoring configuration..."
kubectl apply -f "$MANIFEST_DIR/03-monitoring.yaml"

# Deploy monitoring pods (Prometheus and Grafana)
echo "  Step 4: Deploying Prometheus and Grafana..."
kubectl apply -f "$MANIFEST_DIR/04-monitoring-deployments.yaml"

echo ""
echo "[OK] Kubernetes deployment completed!"
echo ""

# Display service information
echo "Deployed Services:"
echo ""

echo "Global CDN:"
kubectl get services -n cdn-global
echo ""

echo "Regional CDN:"
kubectl get services -n cdn-regional
echo ""

echo "📝 Next steps:"
echo "  1. Wait for services to be ready: kubectl get svc -A -w"
echo "  2. Test access: kubectl get svc -n cdn-global"
echo "  3. View pod logs: kubectl logs -n cdn-global <pod-name>"
echo "  4. Port forward to service: kubectl port-forward -n cdn-global svc/nginx-test-service 8080:80"
