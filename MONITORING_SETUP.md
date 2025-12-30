# Monitoring Stack Setup - COMPLETED

## Status: ✅ FULLY OPERATIONAL

### Components
- **Prometheus**: Running in Kubernetes (`prometheus.monitoring.svc.cluster.local:9090`)
  - Scraping metrics from Kubernetes API servers, nodes, and pods
  - Data storage: In-memory TSDB with 512Mi memory limit
  
- **Grafana**: Running in Kubernetes (`localhost:3000`)
  - Admin User: `admin`
  - Admin Password: `admin123`
  - Prometheus datasource: Automatically provisioned via ConfigMap

### Access Points
1. **Grafana UI**: http://localhost:3000
   - Login: admin / admin123
   - Datasources: Automatically configured Prometheus

2. **Prometheus UI**: http://localhost:9090
   - Available via port-forward (already running on localhost:9090)
   - Targets status: All scrape configs active

### Service Discovery Working
✅ Kubernetes API Server targets
✅ Kubernetes Nodes
✅ Kubernetes Pods (including test applications)
✅ CoreDNS metrics
✅ Prometheus self-monitoring
✅ Grafana self-monitoring

### What Changed
1. Added `grafana-datasources` ConfigMap with Prometheus datasource configuration
2. Updated Grafana Deployment to mount datasource provisioning config
3. Datasource configured to use internal Kubernetes DNS: `http://prometheus:9090`

### How to Use Grafana
1. Access http://localhost:3000
2. Login with admin / admin123
3. Go to Dashboards → Create new dashboard or import existing ones
4. Prometheus is already set as default datasource
5. Start querying with PromQL queries like:
   - `up` - Service/target status
   - `container_memory_usage_bytes` - Memory usage
   - `rate(http_requests_total[5m])` - Request rate

### Troubleshooting
If Grafana can't connect to Prometheus:
1. Check pod is running: `kubectl get pods -n monitoring`
2. Check logs: `kubectl logs grafana-xxx -n monitoring`
3. Verify datasource: `curl -u admin:admin123 http://localhost:3000/api/datasources`
4. Test health: `curl -u admin:admin123 -X POST http://localhost:3000/api/datasources/1/health`

### Next Steps
- Create custom dashboards in Grafana
- Add Prometheus datasource for additional clusters if needed
- Configure alerting rules in Prometheus
- Set up notification channels in Grafana (Slack, PagerDuty, etc.)
