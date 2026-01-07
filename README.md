# Copilot for Infrastructure

A hands-on training environment for teaching infrastructure and operations teams how to use GitHub Copilot for troubleshooting, configuration, and modernization tasks.

## Overview

This project simulates a legacy 3-tier corporate application environment using Docker containers that behave like traditional VMs. It's designed for training sessions where participants learn to leverage AI-assisted troubleshooting with GitHub Copilot.

The environment intentionally uses "legacy" patterns (init scripts, manual configuration) to represent real-world brownfield infrastructure that ops teams maintain.

## Architecture

```text
┌─────────────────────────────────────────────────────────────────┐
│                    corp-lan network (172.21.0.0/16)             │
│                                                                  │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐       │
│  │   frontend   │    │   backend    │    │   database   │       │
│  │   (Apache)   │───▶│   (Java 8)   │───▶│ (PostgreSQL) │       │
│  │ 172.21.0.10  │    │ 172.21.0.11  │    │ 172.21.0.12  │       │
│  │   Port 80    │    │  Port 8080   │    │  Port 5432   │       │
│  └──────────────┘    └──────────────┘    └──────────────┘       │
│         │                   │                   │                │
│         └───────────────────┼───────────────────┘                │
│                             │ (node_exporter :9100)              │
│                    ┌────────▼────────┐                          │
│                    │   prometheus    │                          │
│                    │  172.21.0.20    │                          │
│                    │   Port 9090     │                          │
│                    └─────────────────┘                          │
│                                                                  │
│                    ┌─────────────────┐                          │
│                    │ ansible-control │                          │
│                    │  172.21.0.100   │                          │
│                    │  (Management)   │                          │
│                    └─────────────────┘                          │
└─────────────────────────────────────────────────────────────────┘
```

## Components

| Container         | IP Address   | Role                       | Key Software                              |
| ----------------- | ------------ | -------------------------- | ----------------------------------------- |
| `frontend`        | 172.21.0.10  | Web server / reverse proxy | AlmaLinux 8, Apache httpd, node_exporter  |
| `backend`         | 172.21.0.11  | Application server         | AlmaLinux 8, Java 8, node_exporter        |
| `database`        | 172.21.0.12  | Database server            | AlmaLinux 8, PostgreSQL 13, node_exporter |
| `prometheus`      | 172.21.0.20  | Monitoring                 | Prometheus 2.45                           |
| `ansible-control` | 172.21.0.100 | Configuration management   | AlmaLinux 8, Ansible 2.10                 |

## Prerequisites

- Docker and Docker Compose
- Make (optional, but recommended)
- ~4GB RAM available for containers
- Apple Silicon (ARM64) or Intel x86_64

## Quick Start

```bash
# Clone the repository
git clone https://github.com/navikt/copilot-for-infrastructure.git
cd copilot-for-infrastructure

# Build and start the environment
make up

# Wait for containers to be healthy, then provision with Ansible
make provision

# Verify the stack is working
curl http://localhost:18080/health
curl http://localhost:18080/api/items

# Access Prometheus
open http://localhost:9090
```

## Port Mappings

| Service               | Container Port | Host Port |
| --------------------- | -------------- | --------- |
| Frontend (Apache)     | 80             | 18080     |
| Backend (Java)        | 8080           | 8081      |
| Database (PostgreSQL) | 5432           | 5433      |
| Prometheus            | 9090           | 9090      |
| SSH (frontend)        | 22             | 2222      |
| SSH (backend)         | 22             | 2223      |
| SSH (database)        | 22             | 2224      |

## Makefile Commands

| Command               | Description                                  |
| --------------------- | -------------------------------------------- |
| `make up`             | Build and start all containers               |
| `make down`           | Stop and remove all containers               |
| `make provision`      | Run Ansible to configure golden state        |
| `make reset`          | Reset all containers to working golden state |
| `make break-all`      | Apply all exercise breakages (chaos mode!)   |
| `make shell-frontend` | Open shell in frontend container             |
| `make shell-backend`  | Open shell in backend container              |
| `make shell-database` | Open shell in database container             |
| `make shell-ansible`  | Open shell in ansible-control container      |
| `make logs`           | Tail logs from all containers                |
| `make status`         | Show container status and health             |

## Exercises

The `exercises/` folder contains self-paced troubleshooting scenarios. Each exercise represents a realistic infrastructure problem that sysadmins encounter.

**Suggested order (easy → hard):**

1. **01-apache-forbidden** - Web server returning 403 errors
2. **02-selinux-proxy** - SELinux blocking reverse proxy
3. **03-java-oom** - Java application running out of memory
4. **04-systemd-service** - Service won't start properly
5. **05-pghba-auth** - Database authentication failures
6. **06-firewall-blocked** - Firewall blocking database connections
7. **07-dns-broken** - Hostname resolution failures
8. **08-ansible-broken** - Fix a broken Ansible playbook

Each exercise folder contains:

- `PROBLEM.md` - Symptoms, hints, and what to investigate
- `SOLUTION.md` - Detailed solution walkthrough
- `break.sh` - Script to apply the breakage

### Running Exercises

```bash
# Apply a single exercise breakage
./exercises/01-apache-forbidden/break.sh

# Apply all breakages at once
make break-all

# After solving, reset to golden state
make reset
```

## Using GitHub Copilot

This environment is designed to demonstrate how Copilot can assist with:

### Log Analysis

Paste error logs into Copilot and ask:

- "What does this error mean?"
- "What could cause this Apache error?"
- "How do I fix this PostgreSQL authentication failure?"

### Configuration Help

- "Show me the correct syntax for an Apache VirtualHost with ProxyPass"
- "How do I configure pg_hba.conf for md5 authentication?"
- "Write a systemd service file for a Java application"

### Command Generation

- "How do I check which ports are listening?"
- "Show me how to use tcpdump to capture traffic on port 5432"
- "How do I check SELinux denials?"

### Script Writing

- "Write a bash script to check if all services are running"
- "Create an Ansible playbook to configure firewalld"
- "Write a script to rotate PostgreSQL logs"

## Directory Structure

```text
copilot-for-infrastructure/
├── README.md                 # This file
├── AGENTS.md                 # Instructions for AI agents
├── Makefile                  # Build and management commands
├── docker-compose.yml        # Container orchestration
├── containers/               # Dockerfiles for each container
│   ├── frontend/             # Apache web server
│   ├── backend/              # Java application server
│   ├── database/             # PostgreSQL server
│   ├── ansible-control/      # Ansible management node
│   └── shared-ssh/           # SSH keys for Ansible
├── ansible/                  # Ansible configuration
│   ├── ansible.cfg           # Ansible settings
│   ├── inventory/            # Host inventory
│   ├── playbooks/            # Playbooks
│   └── roles/                # Ansible roles
├── app/                      # Backend Java application
├── docs/                     # Documentation
│   └── INFRASTRUCTURE.md     # Legacy infra docs (intentionally outdated)
├── prometheus/               # Prometheus configuration
└── exercises/                # Troubleshooting exercises
    ├── 01-apache-forbidden/
    ├── 02-selinux-proxy/
    └── ...
```

## Tips for Workshop Facilitators

1. **Start with the working state** - Run `make provision` and demonstrate the working application before breaking things

2. **Show the monitoring** - Use Prometheus queries to show system metrics:

   ```bash
   # Check if all exporters are up
   curl 'http://localhost:9090/api/v1/query?query=up'

   # Check CPU usage
   curl 'http://localhost:9090/api/v1/query?query=node_cpu_seconds_total'
   ```

3. **Encourage exploration** - Let participants use Copilot to discover commands they don't know

4. **Pair programming** - Have participants work in pairs, one driving and one consulting Copilot

## Troubleshooting the Environment

### Containers won't start

```bash
# Check Docker daemon is running
docker info

# Check for port conflicts
lsof -i :8080
lsof -i :9090
```

### Ansible provisioning fails

```bash
# SSH into ansible-control and run manually
make shell-ansible
ansible-playbook -i inventory/hosts playbooks/site.yml -vvv
```

### Reset not working

```bash
# Nuclear option - rebuild everything
make down
docker volume prune -f
make up
make provision
```

## License

MIT
