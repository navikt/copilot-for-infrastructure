# Exercise 06: Firewall Blocking Database

## Scenario

The backend application was working fine, but after a "security hardening" update, it can no longer connect to the database. The database is running and accepting local connections. Network team says "the firewall is configured correctly."

## Symptoms

```bash
# API fails with database error
curl http://localhost:8080/api/items
# {"error": "Database error", "message": "Connection refused"}

# Database is running locally
make shell-database
sudo -u postgres psql -c "SELECT 1"
# Works fine

# But backend can't connect
make shell-backend
nc -zv database 5432
# Connection refused or timeout
```

## What to Investigate

1. **Firewall status**: Is firewalld/iptables running?
2. **Firewall rules**: What rules are configured?
3. **Network connectivity**: Can you ping between hosts?
4. **Port status**: Is PostgreSQL listening on the right interface?

## Useful Commands

```bash
# SSH into database container
make shell-database

# Check firewall status
systemctl status firewalld
firewall-cmd --state
iptables -L -n

# List firewall rules
firewall-cmd --list-all
iptables -L INPUT -n -v
iptables -L OUTPUT -n -v

# Check what ports are open
ss -tlnp
netstat -tlnp

# Test connectivity from backend
make shell-backend
ping database
nc -zv database 5432
telnet database 5432

# Check if PostgreSQL is listening on all interfaces
make shell-database
ss -tlnp | grep 5432
```

## Hints

<details>
<summary>Hint 1</summary>
Use `iptables -L -n` to see all firewall rules. Look for rules that DROP or REJECT traffic.
</details>

<details>
<summary>Hint 2</summary>
Check INPUT chain rules on the database server. Is port 5432 allowed?
</details>

<details>
<summary>Hint 3</summary>
You can remove iptables rules with `iptables -D` or flush all rules with `iptables -F` (careful in production!)
</details>

## Ask Copilot

Try asking Copilot:
- "How do I list iptables rules?"
- "How do I allow port 5432 through iptables?"
- "What's the difference between iptables DROP and REJECT?"
- "How do I troubleshoot network connectivity between two servers?"
