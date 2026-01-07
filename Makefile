.PHONY: up down build provision reset break-all logs status clean \
        shell-frontend shell-backend shell-database shell-ansible shell-prometheus

# Default target
.DEFAULT_GOAL := help

# Colors for output
GREEN  := \033[0;32m
YELLOW := \033[0;33m
RED    := \033[0;31m
NC     := \033[0m # No Color

help: ## Show this help message
	@echo "Copilot for Infrastructure - Training Environment"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'

# =============================================================================
# Container Management
# =============================================================================

up: build ## Build and start all containers
	@echo "$(GREEN)Starting containers...$(NC)"
	docker-compose up -d
	@echo "$(GREEN)Waiting for containers to be ready...$(NC)"
	@sleep 5
	@echo "$(GREEN)Containers started. Run 'make provision' to configure the golden state.$(NC)"

down: ## Stop and remove all containers
	@echo "$(YELLOW)Stopping containers...$(NC)"
	docker-compose down

build: ## Build all container images
	@echo "$(GREEN)Building container images...$(NC)"
	docker-compose build

rebuild: ## Rebuild all container images (no cache)
	@echo "$(GREEN)Rebuilding container images (no cache)...$(NC)"
	docker-compose build --no-cache

logs: ## Tail logs from all containers
	docker-compose logs -f

status: ## Show container status and health
	@echo "$(GREEN)Container Status:$(NC)"
	@docker-compose ps
	@echo ""
	@echo "$(GREEN)Health Checks:$(NC)"
	@echo -n "Frontend (Apache): "
	@curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ 2>/dev/null || echo "DOWN"
	@echo ""
	@echo -n "Backend (Java):    "
	@curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health 2>/dev/null || echo "DOWN"
	@echo ""
	@echo -n "Prometheus:        "
	@curl -s -o /dev/null -w "%{http_code}" http://localhost:9090/-/healthy 2>/dev/null || echo "DOWN"
	@echo ""

clean: down ## Remove containers, images, and volumes
	@echo "$(RED)Cleaning up everything...$(NC)"
	docker-compose down -v --rmi local
	docker volume prune -f

# =============================================================================
# Ansible Provisioning
# =============================================================================

provision: ## Run Ansible to configure the golden state
	@echo "$(GREEN)Provisioning with Ansible...$(NC)"
	docker-compose exec ansible-control ansible-playbook -i /ansible/inventory/hosts /ansible/playbooks/site.yml

provision-verbose: ## Run Ansible with verbose output
	@echo "$(GREEN)Provisioning with Ansible (verbose)...$(NC)"
	docker-compose exec ansible-control ansible-playbook -i /ansible/inventory/hosts /ansible/playbooks/site.yml -vvv

reset: ## Reset all containers to working golden state
	@echo "$(GREEN)Resetting to golden state...$(NC)"
	docker-compose exec ansible-control ansible-playbook -i /ansible/inventory/hosts /ansible/playbooks/site.yml --tags reset
	@echo "$(GREEN)Reset complete. All services should be working.$(NC)"

# =============================================================================
# Exercise Breakages
# =============================================================================

break-all: ## Apply all exercise breakages (chaos mode!)
	@echo "$(RED)Applying all breakages...$(NC)"
	@for script in exercises/*/break.sh; do \
		echo "$(YELLOW)Running $$script...$(NC)"; \
		bash "$$script"; \
	done
	@echo "$(RED)All breakages applied. Good luck!$(NC)"

break-01: ## Break: Apache 403 Forbidden
	@echo "$(YELLOW)Applying Exercise 01: Apache Forbidden$(NC)"
	@bash exercises/01-apache-forbidden/break.sh

break-02: ## Break: SELinux Proxy
	@echo "$(YELLOW)Applying Exercise 02: SELinux Proxy$(NC)"
	@bash exercises/02-selinux-proxy/break.sh

break-03: ## Break: Java OOM
	@echo "$(YELLOW)Applying Exercise 03: Java OOM$(NC)"
	@bash exercises/03-java-oom/break.sh

break-04: ## Break: Systemd Service
	@echo "$(YELLOW)Applying Exercise 04: Systemd Service$(NC)"
	@bash exercises/04-systemd-service/break.sh

break-05: ## Break: PostgreSQL Auth
	@echo "$(YELLOW)Applying Exercise 05: PostgreSQL Auth$(NC)"
	@bash exercises/05-pghba-auth/break.sh

break-06: ## Break: Firewall
	@echo "$(YELLOW)Applying Exercise 06: Firewall$(NC)"
	@bash exercises/06-firewall-blocked/break.sh

break-07: ## Break: DNS
	@echo "$(YELLOW)Applying Exercise 07: DNS$(NC)"
	@bash exercises/07-dns-broken/break.sh

break-08: ## Break: Ansible Playbook
	@echo "$(YELLOW)Applying Exercise 08: Ansible Playbook$(NC)"
	@bash exercises/08-ansible-broken/break.sh

# =============================================================================
# Shell Access
# =============================================================================

shell-frontend: ## Open shell in frontend container
	docker-compose exec frontend /bin/bash

shell-backend: ## Open shell in backend container
	docker-compose exec backend /bin/bash

shell-database: ## Open shell in database container
	docker-compose exec database /bin/bash

shell-ansible: ## Open shell in ansible-control container
	docker-compose exec ansible-control /bin/bash

shell-prometheus: ## Open shell in prometheus container
	docker-compose exec prometheus /bin/sh

# =============================================================================
# Utility Commands
# =============================================================================

test-app: ## Test the application endpoints
	@echo "$(GREEN)Testing application...$(NC)"
	@echo "Health check:"
	@curl -s http://localhost:8080/health | head -20
	@echo ""
	@echo "API items:"
	@curl -s http://localhost:8080/api/items | head -20
	@echo ""

prom-query: ## Example Prometheus query (usage: make prom-query Q="up")
	@curl -s "http://localhost:9090/api/v1/query?query=$(Q)" | python3 -m json.tool 2>/dev/null || \
	curl -s "http://localhost:9090/api/v1/query?query=$(Q)"

prom-targets: ## Show Prometheus scrape targets
	@curl -s http://localhost:9090/api/v1/targets | python3 -m json.tool 2>/dev/null || \
	curl -s http://localhost:9090/api/v1/targets

ssh-keygen: ## Generate SSH keys for Ansible (if needed)
	@echo "$(GREEN)Generating SSH keys...$(NC)"
	@mkdir -p containers/base/ssh
	@ssh-keygen -t rsa -b 4096 -f containers/base/ssh/id_rsa -N "" -C "ansible@copilot-infra"
	@echo "$(GREEN)SSH keys generated in containers/base/ssh/$(NC)"
