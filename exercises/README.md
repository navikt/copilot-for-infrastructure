# Troubleshooting Exercises

This folder contains self-paced troubleshooting exercises designed to demonstrate how GitHub Copilot can assist with infrastructure and operations tasks.

## How to Use These Exercises

### Prerequisites
1. The environment is running (`make up` + `make provision`)
2. You have GitHub Copilot enabled in your editor
3. You have terminal access (VS Code terminal or separate)

### Workflow

1. **Break something**: Run the `break.sh` script for an exercise
   ```bash
   ./exercises/01-apache-forbidden/break.sh
   ```

2. **Observe symptoms**: Check if the application is working
   ```bash
   curl http://localhost:8080/
   curl http://localhost:8080/health
   curl http://localhost:8080/api/items
   ```

3. **Investigate**: SSH into containers and use Copilot to help
   ```bash
   make shell-frontend   # For Apache issues
   make shell-backend    # For Java issues
   make shell-database   # For PostgreSQL issues
   ```

4. **Ask Copilot for help**:
   - Paste error messages and ask "What does this mean?"
   - Ask "How do I check Apache logs?"
   - Ask "What could cause a 403 Forbidden error?"

5. **Fix the issue**: Apply the fix you discovered

6. **Reset**: Return to working state when done
   ```bash
   make reset
   ```

## Exercise Overview

| Exercise             | Difficulty | Topic                   | Time Estimate |
| -------------------- | ---------- | ----------------------- | ------------- |
| 01-apache-forbidden  | Easy       | Web server permissions  | 10-15 min     |
| 02-selinux-proxy     | Medium     | SELinux contexts        | 15-20 min     |
| 03-java-oom          | Medium     | JVM memory tuning       | 15-20 min     |
| 04-systemd-service   | Easy       | Service management      | 10-15 min     |
| 05-pghba-auth        | Easy       | Database authentication | 10-15 min     |
| 06-firewall-blocked  | Medium     | Firewall rules          | 15-20 min     |
| 07-dns-broken        | Easy       | Name resolution         | 10-15 min     |
| 08-ansible-broken    | Medium     | Ansible playbooks       | 20-30 min     |
| 09-prometheus-alerts | Medium     | Monitoring & metrics    | 15-20 min     |
| 10-log-analysis      | Easy       | Log investigation       | 15-20 min     |

## Suggested Order

For beginners, we recommend this progression:

1. **Start easy**: 01, 04, 05, 07, 10
2. **Medium challenges**: 02, 03, 06, 09
3. **Advanced**: 08 (combines multiple skills)

## Tips for Using Copilot

### Log Analysis
When you encounter an error, copy the relevant log lines and ask Copilot:
- "Explain this error message"
- "What could cause this Apache error?"
- "How do I fix this PostgreSQL authentication failure?"

### Command Discovery
Ask Copilot for commands you don't remember:
- "How do I check which ports are listening?"
- "Show me how to use tcpdump to capture traffic on port 5432"
- "How do I restart Apache on CentOS?"

### Configuration Help
Ask Copilot for correct syntax:
- "Show me the correct format for pg_hba.conf"
- "Write an Apache VirtualHost with ProxyPass"
- "What JVM flags control heap size?"

### Script Generation
Ask Copilot to write diagnostic scripts:
- "Write a bash script to check if all services are running"
- "Create a script to test database connectivity"
- "Write a healthcheck script for this application"

## Chaos Mode

Want a real challenge? Apply all breakages at once:

```bash
make break-all
```

Then work through fixing each issue. This simulates a real "everything is broken" scenario!

## Monitoring Queries

Use Prometheus to observe system state:

```bash
# Check if all exporters are up
curl -s 'http://localhost:9090/api/v1/query?query=up' | python3 -m json.tool

# Check CPU usage
curl -s 'http://localhost:9090/api/v1/query?query=rate(node_cpu_seconds_total{mode="user"}[5m])'

# Check memory usage
curl -s 'http://localhost:9090/api/v1/query?query=node_memory_MemAvailable_bytes'
```
