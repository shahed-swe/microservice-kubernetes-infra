#!/bin/bash

# Setup script for local CDN infrastructure
# This script sets up Docker containers for databases and object storage

set -e

echo "Starting CDN Infrastructure Setup..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "[FAILED] Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "[FAILED] docker-compose is not installed. Please install Docker Compose first."
    exit 1
fi

cd "$(dirname "$0")/docker"

echo "Creating and starting Docker containers..."
docker-compose up -d

echo "Waiting for services to be healthy..."
sleep 10

# Check PostgreSQL Global
echo "Checking PostgreSQL Global health..."
for i in {1..30}; do
    if docker exec postgres-global pg_isready -U cdn_admin_global &> /dev/null; then
        echo "[OK] PostgreSQL Global is healthy"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "[FAILED] PostgreSQL Global failed to start"
        exit 1
    fi
    echo "Waiting for PostgreSQL Global... ($i/30)"
    sleep 1
done

# Check PostgreSQL Regional
echo "Checking PostgreSQL Regional health..."
for i in {1..30}; do
    if docker exec postgres-regional pg_isready -U cdn_admin_regional &> /dev/null; then
        echo "[OK] PostgreSQL Regional is healthy"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "[FAILED] PostgreSQL Regional failed to start"
        exit 1
    fi
    echo "Waiting for PostgreSQL Regional... ($i/30)"
    sleep 1
done

# Check MinIO
echo "Checking MinIO health..."
for i in {1..30}; do
    if curl -f http://localhost:9000/minio/health/live &> /dev/null; then
        echo "[OK] MinIO is healthy"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "[FAILED] MinIO failed to start"
        exit 1
    fi
    echo "Waiting for MinIO... ($i/30)"
    sleep 1
done

echo ""
echo "[OK] All services are running!"
echo ""
echo "Service Endpoints:"
echo "  PostgreSQL Global:   localhost:5432 (User: cdn_admin_global)"
echo "  PostgreSQL Regional: localhost:5433 (User: cdn_admin_regional)"
echo "  MinIO Console:       http://localhost:9001"
echo "  MinIO API:           http://localhost:9000"
echo "  pgAdmin:             http://localhost:5050"
echo ""
echo "Default Credentials:"
echo "  MinIO User:     minioadmin"
echo "  MinIO Password: minioadmin123"
echo "  pgAdmin User:   admin@example.com"
echo "  pgAdmin Pass:   admin123"
echo ""
echo "Next steps:"
echo "  1. Create bucket in MinIO: 'cdn-config-bundles'"
echo "  2. Test database connections with: ./test-connectivity.sh"
echo "  3. Deploy to Kubernetes: ./deploy-to-k8s.sh"
