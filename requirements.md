*Context*:
Before we can build anything, we need the underlying infrastructure - servers, databases, and storage. This is like building the foundation and plumbing before constructing a house. Everything else depends on this being stable and reliable.

**Scope**:
- Create Kubernetes clusters for hosting Global and Regional Control Plane services
- Set up highly-available PostgreSQL databases (one global, one regional to start)
- Set up S3-compatible object storage for configuration bundles
- Configure networking (firewalls, load balancers, DNS)
- Install basic monitoring infrastructure

**Success Criteria**:
- [ ] Kubernetes clusters operational in at least 2 availability zones each
- [ ] Can deploy a test application to Kubernetes and access it
- [ ] Global Postgres database running with 1 primary + 1 replica
- [ ] Regional Postgres database running with 1 primary + 1 replica
- [ ] Object storage bucket created and accessible
- [ ] Can connect from Global K8s cluster to Global Postgres
- [ ] Can connect from Regional K8s cluster to Regional Postgres
- [ ] Prometheus operator installed and scraping basic cluster metrics
- [ ] All components pass health checks

**Dependencies**: None - this is the foundation

**Complexity**: Moderate
**Estimated Time**: 1-2 weeks
**Risk Level**: Low (using proven technologies)

**Implementation Steps**:

1. **Kubernetes Clusters**:
- Use managed Kubernetes service (EKS on AWS, GKE on Google Cloud, or AKS on Azure)
- Create "cdn-global-control" cluster: 3-5 nodes minimum, spread across availability zones
- Create "cdn-regional-uswest" cluster: 3-5 nodes minimum, spread across availability zones
- Configure kubectl access and test with `kubectl get nodes`

2. **Global PostgreSQL**:
- Use managed database service (RDS, Cloud SQL, Azure Database)
- Choose Postgres version 14 or newer
- Instance size: Start with 4 vCPUs, 16GB RAM (can scale later)
- Enable multi-AZ deployment for high availability
- Set up automated backups: daily, 30-day retention
- Create initial database: `cdn_global`
- Create admin user with strong password, store in secrets manager

3. **Regional PostgreSQL**:
- Same specs as global, but in regional cluster's region
- Create database: cdn\_regional\_uswest
- Separate instance (DO NOT share with global)

4. **Object Storage**:
- Create bucket: `cdn-config-bundles`
- Enable versioning (keep old versions of files)
- Set lifecycle policy: Delete versions older than 90 days
- Configure access: Only accessible from K8s clusters (use service accounts/IAM roles)

5. **Networking**:
- Create VPCs (Virtual Private Clouds) if not using defaults
- Configure security groups/firewall rules:
- Allow K8s clusters to reach databases on port 5432
- Allow external HTTPS (443) to K8s ingress
- Allow inter-cluster communication for GCP ↔ RCP
- Set up load balancers for K8s ingress

6. **Monitoring Foundation**:
- Install Prometheus operator in K8s: `helm install prometheus prometheus-community/kube-prometheus-stack`
- Verify Prometheus UI accessible
- Install Grafana (usually included with above)
- Verify basic cluster metrics appearing

**Testing**:
- Deploy nginx test pod to each K8s cluster and access via browser
- Connect to each database using psql client, create test table, insert data, query it
- Upload test file to object storage, download it, verify contents match
- Check Prometheus for cluster CPU/memory metrics
- Simulate: Stop one database replica → verify automatic failover → verify apps reconnect

**Deliverables**:
- Infrastructure diagram showing all components
- Connection strings and credentials (in secrets manager)
- kubectl config files for operators
- Runbook: "How to access databases" "How to check Kubernetes health"

---