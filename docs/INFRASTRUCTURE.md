# Infrastructure Documentation

**Last Updated:** March 2019
**Author:** Terje Johansen (left the company)
**Status:** Production

> ⚠️ This document may be outdated. Contact the Platform Team for current information.

---

## Overview

The Item Management System (IMS) is a mission-critical application used by the inventory department. It runs on our standard CentOS 7 infrastructure and follows the 3-tier architecture pattern mandated by the Enterprise Architecture team.

## System Components

### Frontend Server (IMSWEB01)

| Property   | Value                      |
| ---------- | -------------------------- |
| Hostname   | frontend.corp.local        |
| IP Address | 172.20.0.10                |
| OS         | CentOS 7.9                 |
| Role       | Web Server / Load Balancer |
| Owner      | Web Operations Team        |

**Services:**
- Apache HTTPD 2.4 (systemctl start httpd)
- SSL certificates in `/etc/pki/tls/certs/`
- Configuration in `/etc/httpd/conf.d/app.conf`

**Important Notes:**
- SELinux must be in enforcing mode for compliance
- SSL termination happens here - backend traffic is unencrypted
- Apache runs as `apache` user
- Log rotation configured in `/etc/logrotate.d/httpd`

### Application Server (IMSAPP01)

| Property   | Value                    |
| ---------- | ------------------------ |
| Hostname   | backend.corp.local       |
| IP Address | 172.20.0.11              |
| OS         | CentOS 7.9               |
| Role       | Java Application Server  |
| Owner      | Application Support Team |

**Services:**
- Java 8 OpenJDK (required version - do not upgrade!)
- Application JAR in `/opt/app/backend.jar`
- Runs via systemd: `systemctl start backend-app`
- JVM options in `/etc/sysconfig/backend-app`

**JVM Configuration:**
```
JAVA_OPTS="-Xms512m -Xmx1024m -XX:+UseG1GC"
```

**Important Notes:**
- Application listens on port 8080 (HTTP only)
- Database connection configured via environment variables
- Logs written to `/var/log/app/backend.log`
- Health endpoint: `http://localhost:8080/health`
- The app user is `appuser` with restricted shell

### Database Server (IMSDB01)

| Property   | Value               |
| ---------- | ------------------- |
| Hostname   | database.corp.local |
| IP Address | 172.20.0.12         |
| OS         | CentOS 7.9          |
| Role       | PostgreSQL Database |
| Owner      | DBA Team            |

**Services:**
- PostgreSQL 13 (from PGDG repository)
- Data directory: `/var/lib/pgsql/13/data`
- Service: `systemctl start postgresql-13`

**Database Details:**
- Database name: `appdb`
- Application user: `appuser`
- Password: Stored in Vault (ask DBA team)
- Connection string: `jdbc:postgresql://database:5432/appdb`

**Backup Schedule:**
- Full backup: Daily at 02:00 via pg_dump
- WAL archiving: Enabled, archived to `/backup/wal/`
- Retention: 30 days

**Important Notes:**
- pg_hba.conf allows connections from 172.20.0.0/16 subnet only
- `max_connections` set to 100 (increase requires restart)
- Tablespace on `/data` volume (100GB allocated)

## Network Architecture

```
Internet
    │
    ▼
┌─────────┐
│ HAProxy │  (External LB - managed by Network Team)
│ :443    │
└────┬────┘
     │
     ▼
┌─────────────────────────────────────────────────────────────┐
│                    DMZ Network                               │
│                                                              │
│    ┌──────────────┐                                         │
│    │   IMSWEB01   │  frontend.corp.local                    │
│    │   :80/:443   │                                         │
│    └──────┬───────┘                                         │
│           │                                                  │
└───────────┼──────────────────────────────────────────────────┘
            │
┌───────────┼──────────────────────────────────────────────────┐
│           ▼              Corporate Network                   │
│    ┌──────────────┐    ┌──────────────┐                     │
│    │   IMSAPP01   │───▶│   IMSDB01    │                     │
│    │    :8080     │    │    :5432     │                     │
│    └──────────────┘    └──────────────┘                     │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

## Firewall Rules

| Source     | Destination | Port | Protocol | Purpose           |
| ---------- | ----------- | ---- | -------- | ----------------- |
| HAProxy    | IMSWEB01    | 80   | TCP      | HTTP traffic      |
| HAProxy    | IMSWEB01    | 443  | TCP      | HTTPS traffic     |
| IMSWEB01   | IMSAPP01    | 8080 | TCP      | App proxy         |
| IMSAPP01   | IMSDB01     | 5432 | TCP      | Database          |
| Monitoring | All servers | 9100 | TCP      | Prometheus scrape |
| Ansible    | All servers | 22   | TCP      | SSH management    |

## Monitoring

### Prometheus

- URL: http://prometheus.corp.local:9090
- Scrape interval: 15 seconds
- Retention: 15 days

### Key Metrics

| Metric                      | Alert Threshold | Description             |
| --------------------------- | --------------- | ----------------------- |
| `up`                        | 0               | Service availability    |
| `node_cpu_seconds_total`    | >90% for 5m     | CPU saturation          |
| `node_memory_MemFree_bytes` | <500MB          | Memory exhaustion       |
| `node_disk_io_time_seconds` | >80% for 5m     | Disk I/O saturation     |
| `pg_up`                     | 0               | PostgreSQL availability |

### Grafana Dashboards

- Node Exporter Full: Overview of all servers
- PostgreSQL Database: Database-specific metrics
- Application: JVM metrics and response times

## Runbooks

### Starting the Application Stack

1. Start database first:
   ```bash
   ssh root@database.corp.local
   systemctl start postgresql-13
   # Wait for PostgreSQL to be ready
   pg_isready -h localhost -p 5432
   ```

2. Start application server:
   ```bash
   ssh root@backend.corp.local
   systemctl start backend-app
   # Verify health
   curl http://localhost:8080/health
   ```

3. Start web server:
   ```bash
   ssh root@frontend.corp.local
   systemctl start httpd
   # Verify proxy
   curl http://localhost/health
   ```

### Restarting Services

**Apache:**
```bash
systemctl restart httpd
# Check for config errors first:
apachectl configtest
```

**Java Application:**
```bash
systemctl restart backend-app
# Monitor startup:
tail -f /var/log/app/backend.log
```

**PostgreSQL:**
```bash
systemctl restart postgresql-13
# Note: This will disconnect all clients!
```

### Checking Logs

| Service    | Log Location                    |
| ---------- | ------------------------------- |
| Apache     | `/var/log/httpd/error_log`      |
| Apache     | `/var/log/httpd/app_access.log` |
| Backend    | `/var/log/app/backend.log`      |
| PostgreSQL | `/var/lib/pgsql/13/data/log/`   |
| System     | `journalctl -u <service-name>`  |

### Common Issues

#### "Connection refused" to database

1. Check PostgreSQL is running: `systemctl status postgresql-13`
2. Check firewall: `firewall-cmd --list-ports`
3. Check pg_hba.conf allows client IP
4. Verify port binding: `ss -tlnp | grep 5432`

#### Apache returns 403 Forbidden

1. Check SELinux: `getenforce` and `audit2why < /var/log/audit/audit.log`
2. Check file permissions on DocumentRoot
3. Check Directory configuration in Apache config
4. Verify user/group ownership (should be apache:apache)

#### Java application won't start

1. Check available memory: `free -m`
2. Review JVM options in `/etc/sysconfig/backend-app`
3. Check if port 8080 is already in use
4. Look for errors in `/var/log/app/backend.log`
5. Verify database connectivity

#### High CPU on database server

1. Check for long-running queries: `SELECT * FROM pg_stat_activity;`
2. Look for missing indexes: `EXPLAIN ANALYZE <slow_query>`
3. Check for lock contention
4. Review `pg_stat_statements` for query patterns

## Maintenance Windows

- **Standard:** Sundays 02:00-06:00
- **Emergency:** Contact On-Call Lead
- **Change freeze:** Last 2 weeks of each quarter

## Contacts

| Role               | Name             | Phone          |
| ------------------ | ---------------- | -------------- |
| Application Owner  | Kari Nordmann    | +47 XXX XX XXX |
| DBA Team Lead      | Ole Hansen       | +47 XXX XX XXX |
| Network Operations | network-ops@corp | N/A            |
| Platform Team      | platform@corp    | N/A            |

## Change History

| Date       | Author         | Change                           |
| ---------- | -------------- | -------------------------------- |
| 2019-03-15 | Terje Johansen | Initial documentation            |
| 2019-06-22 | Terje Johansen | Added runbooks section           |
| 2019-09-01 | Kari Nordmann  | Updated contact information      |
| 2020-01-15 | Ole Hansen     | Updated PostgreSQL to version 13 |

---

*For infrastructure changes, submit a ticket to ServiceNow queue "Platform-Infra".*

*Note: This system is scheduled for migration to Kubernetes in Q4 2023.*
