# Makefile for CDN Infrastructure Management

.PHONY: help local-setup local-test local-deploy local-clean k8s-deploy k8s-logs terraform-plan terraform-apply terraform-destroy

help:
	@echo "CDN Infrastructure Management"
	@echo ""
	@echo "Local Development:"
	@echo "  make local-setup          Start local Docker infrastructure"
	@echo "  make local-test           Test local infrastructure connectivity"
	@echo "  make local-deploy         Deploy to local Kubernetes"
	@echo "  make local-clean          Clean up local infrastructure"
	@echo ""
	@echo "Kubernetes:"
	@echo "  make k8s-deploy           Deploy manifests to Kubernetes"
	@echo "  make k8s-logs             View Kubernetes logs"
	@echo "  make k8s-describe         Describe Kubernetes resources"
	@echo ""
	@echo "Cloud (Terraform):"
	@echo "  make terraform-init       Initialize Terraform"
	@echo "  make terraform-plan       Plan Terraform deployment"
	@echo "  make terraform-apply      Apply Terraform deployment"
	@echo "  make terraform-destroy    Destroy cloud infrastructure"
	@echo ""

local-setup:
	@echo "Starting local infrastructure..."
	chmod +x setup-local.sh
	./setup-local.sh

local-test:
	@echo "Testing local infrastructure..."
	chmod +x test-connectivity.sh
	./test-connectivity.sh

local-deploy:
	@echo "Deploying to local Kubernetes..."
	chmod +x deploy-to-k8s.sh
	./deploy-to-k8s.sh

local-clean:
	@echo "Cleaning up local infrastructure..."
	chmod +x cleanup.sh
	./cleanup.sh

k8s-deploy:
	@echo "Deploying Kubernetes manifests..."
	kubectl apply -f kubernetes/

k8s-logs:
	@echo "Global CDN Logs:"
	@kubectl logs -n cdn-global -f --all-containers=true --tail=50

k8s-describe:
	@echo "Global CDN Resources:"
	@kubectl describe all -n cdn-global
	@echo ""
	@echo "Regional CDN Resources:"
	@kubectl describe all -n cdn-regional

terraform-init:
	@echo "Initializing Terraform..."
	cd terraform && terraform init

terraform-plan:
	@echo "Planning Terraform deployment (dev)..."
	cd terraform && terraform plan -var-file=terraform-dev.tfvars -out=tfplan

terraform-apply:
	@echo "Applying Terraform deployment..."
	cd terraform && terraform apply tfplan

terraform-destroy:
	@echo "WARNING: This will destroy cloud infrastructure!"
	@read -p "Continue? (yes/no): " confirm && [ "$$confirm" = "yes" ] && cd terraform && terraform destroy -var-file=terraform-dev.tfvars
