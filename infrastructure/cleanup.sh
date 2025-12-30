#!/bin/bash

# Cleanup script for local CDN infrastructure
# This script removes Docker containers and Kubernetes resources

set -e

echo "CDN Infrastructure Cleanup"
echo ""

read -p "Are you sure you want to clean up all infrastructure? This cannot be undone. (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""

# Stop and remove Docker containers
echo "Stopping Docker containers..."
cd "$(dirname "$0")/docker"
if docker-compose down -v &> /dev/null; then
    echo "[OK] Docker containers stopped and removed"
else
    echo "[INFO] Docker containers already stopped"
fi

echo ""

# Remove Kubernetes resources
echo "Removing Kubernetes resources..."
MANIFEST_DIR="$(dirname "$0")/kubernetes"

if kubectl delete namespace cdn-global &> /dev/null; then
    echo "[OK] Removed cdn-global namespace"
fi

if kubectl delete namespace cdn-regional &> /dev/null; then
    echo "[OK] Removed cdn-regional namespace"
fi

if kubectl delete namespace monitoring &> /dev/null; then
    echo "[OK] Removed monitoring namespace"
fi

echo ""
echo "[OK] Cleanup completed!"
