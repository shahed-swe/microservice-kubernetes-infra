-- Global CDN Database Initialization
-- Create tables for global control plane

-- Create schema for global services
CREATE SCHEMA IF NOT EXISTS global;

-- Table for cluster metadata
CREATE TABLE IF NOT EXISTS global.clusters (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    region VARCHAR(100) NOT NULL,
    type VARCHAR(50) NOT NULL,
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table for configuration bundles
CREATE TABLE IF NOT EXISTS global.config_bundles (
    id SERIAL PRIMARY KEY,
    bundle_name VARCHAR(255) NOT NULL,
    version VARCHAR(50) NOT NULL,
    s3_path VARCHAR(500) NOT NULL,
    size_bytes BIGINT,
    checksum VARCHAR(64),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) DEFAULT 'active'
);

-- Table for deployment tracking
CREATE TABLE IF NOT EXISTS global.deployments (
    id SERIAL PRIMARY KEY,
    cluster_id INTEGER REFERENCES global.clusters(id),
    bundle_id INTEGER REFERENCES global.config_bundles(id),
    status VARCHAR(50),
    deployed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better query performance
CREATE INDEX idx_clusters_region ON global.clusters(region);
CREATE INDEX idx_deployments_status ON global.deployments(status);
CREATE INDEX idx_config_bundles_version ON global.config_bundles(version);

-- Grant permissions
GRANT ALL PRIVILEGES ON SCHEMA global TO cdn_admin_global;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA global TO cdn_admin_global;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA global TO cdn_admin_global;
