# Solution: Exercise 07 - DNS Resolution Failure

## Root Cause

The `/etc/hosts` file was modified to remove or corrupt the entry for the "database" hostname. Without this entry, the backend cannot resolve the hostname to an IP address.

## Investigation Steps

### 1. Test name resolution

```bash
ping database
# ping: database: Name or service not known

getent hosts database
# No output (not found)
```

### 2. Check /etc/hosts

```bash
cat /etc/hosts
```

You'll see the database entry is missing or points to wrong IP:
```
127.0.0.1   localhost
172.20.0.10 frontend
172.20.0.11 backend
# database entry missing or wrong!
```

### 3. Verify the correct IP

```bash
# Database container has IP 172.20.0.12
ping 172.20.0.12
# Works!

nc -zv 172.20.0.12 5432
# Connection succeeded
```

## The Fix

### Add the correct hosts entry

```bash
echo "172.20.0.12 database database.corp.local" >> /etc/hosts
```

Or edit the file:
```bash
vi /etc/hosts
```

Add:
```
172.20.0.12 database database.corp.local
```

### Verify the fix

```bash
getent hosts database
# 172.20.0.12    database database.corp.local

ping database
# Works!

curl http://localhost:8080/api/items
# Returns data
```

## Understanding Linux Name Resolution

### Resolution order (nsswitch.conf)

```bash
cat /etc/nsswitch.conf | grep hosts
# hosts: files dns
```

This means:
1. First check `/etc/hosts` (files)
2. Then query DNS servers (dns)

### /etc/hosts format

```
IP_ADDRESS    HOSTNAME    [ALIASES...]
172.20.0.12   database    database.corp.local db
```

### DNS configuration (/etc/resolv.conf)

```bash
cat /etc/resolv.conf
# nameserver 127.0.0.11  (Docker's internal DNS)
```

Docker provides internal DNS for container names, but `/etc/hosts` entries take precedence.

## Debugging tools comparison

| Tool                    | Use case                       |
| ----------------------- | ------------------------------ |
| `ping hostname`         | Quick connectivity test        |
| `getent hosts hostname` | Check what the system resolves |
| `nslookup hostname`     | Query DNS specifically         |
| `dig hostname`          | Detailed DNS query             |
| `host hostname`         | Simple DNS lookup              |

## What Copilot Could Help With

1. **Understanding**: "How does Linux resolve hostnames?"
2. **Syntax**: "What is the format of /etc/hosts?"
3. **Debugging**: "Why can I ping an IP but not a hostname?"
4. **Docker**: "How does Docker DNS work?"

## Prevention

1. Use Ansible to manage /etc/hosts across all servers
2. Use proper DNS infrastructure for production
3. Consider using IP addresses in configs with hostname aliases
4. Monitor name resolution as part of health checks
