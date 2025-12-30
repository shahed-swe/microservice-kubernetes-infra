-- Regional CDN Database Initialization
-- Create tables for regional control plane

-- Create schema for regional services
CREATE SCHEMA IF NOT EXISTS regional;

-- Table for edge servers/nodes
CREATE TABLE IF NOT EXISTS regional.edge_nodes (
    id SERIAL PRIMARY KEY,
    node_name VARCHAR(255) NOT NULL UNIQUE,
    location VARCHAR(255),
    status VARCHAR(50) DEFAULT 'active',
    cpu_cores INTEGER,
    memory_gb INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table for content distribution
CREATE TABLE IF NOT EXISTS regional.content_distribution (
    id SERIAL PRIMARY KEY,
    content_id VARCHAR(255) NOT NULL,
    node_id INTEGER REFERENCES regional.edge_nodes(id),
    status VARCHAR(50),
    last_synced TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table for performance metrics
CREATE TABLE IF NOT EXISTS regional.metrics (
    id SERIAL PRIMARY KEY,
    node_id INTEGER REFERENCES regional.edge_nodes(id),
    metric_type VARCHAR(100),
    metric_value NUMERIC,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_edge_nodes_status ON regional.edge_nodes(status);
CREATE INDEX idx_content_distribution_node ON regional.content_distribution(node_id);
CREATE INDEX idx_metrics_recorded_at ON regional.metrics(recorded_at);

-- Grant permissions
GRANT ALL PRIVILEGES ON SCHEMA regional TO cdn_admin_regional;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA regional TO cdn_admin_regional;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA regional TO cdn_admin_regional;
