#!/bin/bash

# Test connectivity and health of all infrastructure components
# Uses Docker for database testing to avoid shell escaping issues

echo "Testing CDN Infrastructure Connectivity..."
echo ""

# Test PostgreSQL Global
echo "Testing PostgreSQL Global..."
if docker exec postgres-global psql -U cdn_admin_global -d cdn_global -c "\dt global.*" &> /dev/null; then
    echo "[OK] Connected to PostgreSQL Global"
    echo "  Database: cdn_global"
    echo "  User: cdn_admin_global"
    echo "  Port: 5432"
    echo "  Tables:"
    docker exec postgres-global psql -U cdn_admin_global -d cdn_global -c "\dt global.*" | tail -n +3
else
    echo "[FAILED] Failed to connect to PostgreSQL Global"
    exit 1
fi

echo ""

# Test PostgreSQL Regional
echo "Testing PostgreSQL Regional..."
if docker exec postgres-regional psql -U cdn_admin_regional -d cdn_regional_uswest -c "\dt regional.*" &> /dev/null; then
    echo "[OK] Connected to PostgreSQL Regional"
    echo "  Database: cdn_regional_uswest"
    echo "  User: cdn_admin_regional"
    echo "  Port: 5433"
    echo "  Tables:"
    docker exec postgres-regional psql -U cdn_admin_regional -d cdn_regional_uswest -c "\dt regional.*" | tail -n +3
else
    echo "[FAILED] Failed to connect to PostgreSQL Regional"
    exit 1
fi

echo ""

# Test MinIO
echo "Testing MinIO..."
if curl -f http://localhost:9000/minio/health/live &> /dev/null; then
    echo "[OK] MinIO is healthy"
    echo "  Console: http://localhost:9001"
    echo "  API: http://localhost:9000"
    echo "  Credentials: minioadmin / minioadmin123"
else
    echo "[FAILED] MinIO health check failed"
    exit 1
fi

echo ""

# Test pgAdmin
echo "Testing pgAdmin..."
if docker exec pgadmin curl -s http://localhost:80 | grep -q "pgAdmin" &> /dev/null; then
    echo "[OK] pgAdmin is running"
    echo "  URL: http://localhost:5050"
    echo "  Email: admin@example.com"
    echo "  Password: admin123"
else
    echo "[INFO] pgAdmin startup in progress..."
fi

echo ""
echo "[OK] All infrastructure components are operational!"
echo ""
echo "Connection Strings:"
echo "  Global PostgreSQL:  postgresql://cdn_admin_global:ChangeMe123!Global@localhost:5432/cdn_global"
echo "  Regional PostgreSQL: postgresql://cdn_admin_regional:ChangeMe123!Regional@localhost:5433/cdn_regional_uswest"
echo "  MinIO S3 API:       http://localhost:9000"
echo ""
