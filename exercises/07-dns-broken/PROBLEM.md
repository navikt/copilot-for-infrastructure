# Exercise 07: DNS Resolution Failure

## Scenario

After a network configuration change, the backend application reports it cannot connect to the database. Error messages mention the hostname "database" cannot be resolved. Ping by IP works, but ping by hostname fails.

## Symptoms

```bash
# API returns connection error
curl http://localhost:18080/api/items
# {"error": "Database error", "message": "UnknownHostException: database"}

# Hostname resolution fails
make shell-backend
ping database
# ping: database: Name or service not known

# But IP works
ping 172.21.0.12
# Works fine!
```

## What to Investigate

1. **/etc/hosts**: Is the hostname defined there?
2. **/etc/resolv.conf**: DNS configuration
3. **nsswitch.conf**: Name resolution order
4. **DNS tools**: dig, nslookup, getent

## Useful Commands

```bash
# SSH into backend container
make shell-backend

# Check /etc/hosts
cat /etc/hosts

# Check DNS configuration
cat /etc/resolv.conf

# Check name resolution order
cat /etc/nsswitch.conf

# Test name resolution
getent hosts database
nslookup database
dig database

# Direct IP test
ping 172.21.0.12
nc -zv 172.21.0.12 5432
```

## Hints

<details>
<summary>Hint 1</summary>
Check /etc/hosts - this is often the first place Linux looks for hostname resolution.
</details>

<details>
<summary>Hint 2</summary>
The /etc/hosts file might have been corrupted or the database entry might be wrong/missing.
</details>

<details>
<summary>Hint 3</summary>
Add the correct entry to /etc/hosts: `172.21.0.12 database database.corp.local`
</details>

## Ask Copilot

Try asking Copilot:
- "How does Linux resolve hostnames?"
- "What is the format of /etc/hosts?"
- "Explain /etc/nsswitch.conf"
- "How do I troubleshoot DNS resolution in Linux?"
