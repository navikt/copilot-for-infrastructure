# Infrastructure Documentation

**Last Updated:** January 2026
**Author:** Platform Team
**Status:** Training Environment

---

## Overview

This is a **training environment** for Linux infrastructure troubleshooting. It simulates a 3-tier application infrastructure using Docker containers that behave like VMs. The environment runs on AlmaLinux 8 (RHEL-compatible) and is designed for practicing real-world troubleshooting scenarios.

The Item Management System (IMS) follows the classic 3-tier architecture pattern: web server → application server → database.

## System Components

### Frontend Server

| Property      | Value                      |
| ------------- | -------------------------- |
| Hostname      | frontend                   |
| IP Address    | 172.21.0.10                |
| OS            | AlmaLinux 8                |
| Role          | Web Server / Reverse Proxy |
| External Port | 18080 (HTTP), 2222 (SSH)   |

**Services:**
- Apache HTTPD 2.4 with mod_proxy, mod_ssl (`systemctl start httpd`)
- Configuration in `/etc/httpd/conf.d/app.conf`
- node_exporter on port 9100

**Important Notes:**
- SELinux in enforcing mode for compliance
- Apache runs as `apache` user
- Proxies requests to backend:8080
- Health endpoint: `http://localhost/health`
- Log rotation configured in `/etc/logrotate.d/httpd`

### Application Server (Backend)

| Property      | Value                   |
| ------------- | ----------------------- |
| Hostname      | backend                 |
| IP Address    | 172.21.0.11             |
| OS            | AlmaLinux 8             |
| Role          | Java Application Server |
| External Port | 8081 (App), 2223 (SSH)  |

**Services:**
- Java 8 OpenJDK
- Application JAR in `/opt/app/backend.jar`
- Runs via systemd: `systemctl start backend-app`
- node_exporter on port 9100

**JVM Configuration (Environment Variables):**
```
JAVA_OPTS=-Xms256m -Xmx512m
DB_HOST=database
DB_PORT=5432
DB_NAME=appdb
DB_USER=appuser
DB_PASSWORD=apppassword
```

**Important Notes:**
- Application listens on port 8080 (HTTP only)
- Database connection configured via environment variables
- Logs written to `/opt/app/logs/backend.log`
- Health endpoint: `http://localhost:8080/health`

### Database Server

| Property      | Value                         |
| ------------- | ----------------------------- |
| Hostname      | database                      |
| IP Address    | 172.21.0.12                   |
| OS            | AlmaLinux 8                   |
| Role          | PostgreSQL Database           |
| External Port | 5433 (PostgreSQL), 2224 (SSH) |

**Services:**
- PostgreSQL 13
- Data directory: `/var/lib/pgsql/data`
- Service: `systemctl start postgresql-13`
- node_exporter on port 9100

**Database Details:**
- Database name: `appdb`
- Application user: `appuser`
- Password: `apppassword`
- Connection string: `jdbc:postgresql://database:5432/appdb`

**Important Notes:**
- pg_hba.conf allows connections from 172.21.0.0/16 subnet
- `max_connections` set to 100 (increase requires restart)

### Prometheus Server

| Property      | Value                   |
| ------------- | ----------------------- |
| Hostname      | prometheus              |
| IP Address    | 172.21.0.20             |
| Image         | prom/prometheus:v2.45.0 |
| Role          | Monitoring              |
| External Port | 9090                    |

### Ansible Control Node

| Property   | Value              |
| ---------- | ------------------ |
| Hostname   | ansible-control    |
| IP Address | 172.21.0.100       |
| OS         | AlmaLinux 8        |
| Role       | Configuration Mgmt |

**Volumes:**

- `/ansible` - Ansible playbooks and roles (read-only)
- `/exercises` - Troubleshooting exercises (read-only)

## Network Architecture

```text
                    Docker Host (localhost)
                           │
         ┌─────────────────┼─────────────────┐
         │                 │                 │
         ▼                 ▼                 ▼
    :18080 (HTTP)     :8081 (App)      :5433 (PostgreSQL)
    :2222 (SSH)       :2223 (SSH)      :2224 (SSH)
         │                 │                 │
┌────────┼─────────────────┼─────────────────┼────────────────┐
│        ▼                 ▼                 ▼                │
│  ┌──────────┐      ┌──────────┐      ┌──────────┐         │
│  │ frontend │─────▶│ backend  │─────▶│ database │         │
│  │  :80     │      │  :8080   │      │  :5432   │         │
│  │ :9100    │      │  :9100   │      │  :9100   │         │
│  └──────────┘      └──────────┘      └──────────┘         │
│   172.21.0.10       172.21.0.11       172.21.0.12         │
│                                                            │
│  ┌──────────┐      ┌─────────────────┐                    │
│  │prometheus│      │ ansible-control │                    │
│  │  :9090   │      │                 │                    │
│  └──────────┘      └─────────────────┘                    │
│   172.21.0.20          172.21.0.100                       │
│                                                            │
│              Network: corp-lan (172.21.0.0/16)            │
└────────────────────────────────────────────────────────────┘
```

## Port Mappings (Host → Container)

| Host Port | Container  | Container Port | Purpose           |
| --------- | ---------- | -------------- | ----------------- |
| 18080     | frontend   | 80             | HTTP traffic      |
| 2222      | frontend   | 22             | SSH access        |
| 8081      | backend    | 8080           | Direct app access |
| 2223      | backend    | 22             | SSH access        |
| 5433      | database   | 5432           | PostgreSQL        |
| 2224      | database   | 22             | SSH access        |
| 9090      | prometheus | 9090           | Prometheus UI     |

## Internal Network (container-to-container)

| Source          | Destination | Port | Protocol | Purpose        |
| --------------- | ----------- | ---- | -------- | -------------- |
| frontend        | backend     | 8080 | TCP      | App proxy      |
| backend         | database    | 5432 | TCP      | Database       |
| prometheus      | all hosts   | 9100 | TCP      | Node exporter  |
| ansible-control | all hosts   | 22   | TCP      | SSH management |

## Monitoring

### Prometheus

- URL: <http://localhost:9090>
- Scrape interval: 15 seconds
- External labels: `environment=demo`, `project=copilot-infrastructure`

### Scrape Targets

| Job Name   | Target         | Labels                            |
| ---------- | -------------- | --------------------------------- |
| prometheus | localhost:9090 | instance=prometheus               |
| node       | frontend:9100  | instance=frontend, role=webserver |
| node       | backend:9100   | instance=backend, role=appserver  |
| node       | database:9100  | instance=database, role=dbserver  |

### Key Metrics

| Metric                      | Alert Threshold | Description          |
| --------------------------- | --------------- | -------------------- |
| `up`                        | 0               | Service availability |
| `node_cpu_seconds_total`    | >90% for 5m     | CPU saturation       |
| `node_memory_MemFree_bytes` | <500MB          | Memory exhaustion    |
| `node_disk_io_time_seconds` | >80% for 5m     | Disk I/O saturation  |

## Runbooks

### Starting the Environment

Use Docker Compose to manage the environment:

```bash
# Build and start all containers
make up

# Or using docker compose directly
docker compose up -d --build
```

### Shell Access to Containers

```bash
# Access frontend (Apache)
make shell-frontend
# Or: docker exec -it frontend bash

# Access backend (Java app)
make shell-backend
# Or: docker exec -it backend bash

# Access database (PostgreSQL)
make shell-database
# Or: docker exec -it database bash

# Access Ansible control node
make shell-ansible
# Or: docker exec -it ansible-control bash
```

### Checking Service Status (Inside Containers)

**Apache (frontend):**

```bash
systemctl status httpd
apachectl configtest
curl http://localhost/health
```

**Java Application (backend):**

```bash
systemctl status backend-app
curl http://localhost:8080/health
tail -f /opt/app/logs/backend.log
```

**PostgreSQL (database):**

```bash
systemctl status postgresql-13
pg_isready -h localhost -p 5432
psql -U appuser -d appdb -c "SELECT 1"
```

### Provisioning with Ansible

From the ansible-control container:

```bash
cd /ansible
ansible-playbook -i inventory/hosts playbooks/site.yml
```

### Checking Logs

| Service    | Log Location                    | Command                                 |
| ---------- | ------------------------------- | --------------------------------------- |
| Apache     | `/var/log/httpd/error_log`      | `tail -f /var/log/httpd/error_log`      |
| Apache     | `/var/log/httpd/app_access.log` | `tail -f /var/log/httpd/app_access.log` |
| Backend    | `/opt/app/logs/backend.log`     | `tail -f /opt/app/logs/backend.log`     |
| PostgreSQL | `/var/lib/pgsql/13/data/log/`   | `journalctl -u postgresql-13`           |
| System     | journald                        | `journalctl -u <service-name>`          |

### Common Issues

#### "Connection refused" to database

1. Check PostgreSQL is running: `systemctl status postgresql-13`
2. Check pg_hba.conf allows client IP
3. Verify port binding: `ss -tlnp | grep 5432`

#### Apache returns 403 Forbidden

1. Check SELinux: `getenforce` and `ausearch -m avc -ts recent`
2. Check file permissions on DocumentRoot
3. Check Directory configuration in Apache config
4. Verify user/group ownership (should be apache:apache)

#### Java application won't start

1. Check available memory: `free -m`
2. Review JVM options (JAVA_OPTS environment variable)
3. Check if port 8080 is already in use: `ss -tlnp | grep 8080`
4. Look for errors in `/opt/app/logs/backend.log`
5. Verify database connectivity

#### 502 Bad Gateway from Apache

1. Check backend is running: `curl http://backend:8080/health`
2. Check proxy configuration in `/etc/httpd/conf.d/app.conf`
3. Check SELinux httpd_can_network_connect: `getsebool httpd_can_network_connect`

## Exercises

This environment includes 10 troubleshooting exercises in `/exercises/`:

| #   | Exercise          | Topic                     |
| --- | ----------------- | ------------------------- |
| 01  | apache-forbidden  | HTTP 403 errors           |
| 02  | selinux-proxy     | SELinux blocking proxy    |
| 03  | java-oom          | JVM OutOfMemory issues    |
| 04  | systemd-service   | Service management        |
| 05  | pghba-auth        | PostgreSQL authentication |
| 06  | firewall-blocked  | Firewall rules            |
| 07  | dns-broken        | DNS resolution            |
| 08  | ansible-broken    | Ansible playbook errors   |
| 09  | prometheus-alerts | Monitoring configuration  |
| 10  | log-analysis      | Log investigation         |

To start an exercise:

```bash
make break-01  # Introduces problem for exercise 01
```

## Change History

| Date       | Author         | Change                                       |
| ---------- | -------------- | -------------------------------------------- |
| 2019-03-15 | Terje Johansen | Initial documentation                        |
| 2019-06-22 | Terje Johansen | Added runbooks section                       |
| 2019-09-01 | Kari Nordmann  | Updated contact information                  |
| 2020-01-15 | Ole Hansen     | Updated PostgreSQL to version 13             |
| 2026-01-08 | Platform Team  | Migrated to Docker/AlmaLinux 8, updated docs |

---

*This is a training environment for infrastructure troubleshooting practice.*
