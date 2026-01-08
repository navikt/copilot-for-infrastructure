# Solution: Exercise 05 - PostgreSQL Authentication Failure

## Root Cause

The `pg_hba.conf` file was modified to only allow connections from `172.21.0.99/32`, but the backend server's IP is `172.21.0.11`. The CIDR range doesn't include the backend.

## Investigation Steps

### 1. Check PostgreSQL logs

```bash
tail -50 /var/lib/pgsql/13/data/log/*.log
```

You should see:
```
FATAL:  no pg_hba.conf entry for host "172.21.0.11", user "appuser", database "appdb", SSL off
```

### 2. Check the backend's IP address

```bash
# From backend container
hostname -I
# Shows: 172.21.0.11
```

### 3. Examine pg_hba.conf

```bash
cat /var/lib/pgsql/13/data/pg_hba.conf
```

You'll see a line like:
```
host    all    all    172.21.0.99/32    md5
```

This only allows connections from 172.21.0.99, not 172.21.0.11.

## The Fix

### Edit pg_hba.conf

```bash
sudo -u postgres vi /var/lib/pgsql/13/data/pg_hba.conf
```

Change the restricted line to allow the whole subnet:
```
host    all    all    172.21.0.0/16    md5
```

Or be specific:
```
host    appdb    appuser    172.21.0.11/32    md5
```

### Reload PostgreSQL

```bash
sudo -u postgres /usr/pgsql-13/bin/pg_ctl reload -D /var/lib/pgsql/13/data
```

### Verify the fix

```bash
# Test from backend
PGPASSWORD=apppassword psql -h database -U appuser -d appdb -c "SELECT 1"

# Test the API
curl http://localhost:18080/api/items
```

## Understanding pg_hba.conf

### File format

```
TYPE    DATABASE    USER    ADDRESS         METHOD
host    appdb       appuser 172.21.0.0/16   md5
```

| Field    | Description                                       |
| -------- | ------------------------------------------------- |
| TYPE     | Connection type: local, host, hostssl             |
| DATABASE | Database name or "all"                            |
| USER     | Username or "all"                                 |
| ADDRESS  | IP/CIDR or hostname                               |
| METHOD   | Authentication: md5, scram-sha-256, trust, reject |

### Common CIDR notations

| CIDR           | Meaning                       |
| -------------- | ----------------------------- |
| 172.21.0.11/32 | Exactly one IP (172.21.0.11)  |
| 172.21.0.0/24  | 172.21.0.0 - 172.21.0.255     |
| 172.21.0.0/16  | 172.21.0.0 - 172.21.255.255   |
| 0.0.0.0/0      | Any IPv4 address (dangerous!) |

## What Copilot Could Help With

1. **Syntax**: "What is the format of pg_hba.conf?"
2. **CIDR**: "Explain CIDR notation for IP addresses"
3. **Security**: "What's the most secure way to configure pg_hba.conf?"
4. **Debugging**: "What does this PostgreSQL error mean: [paste error]"

## Prevention

1. Use Ansible templates to manage pg_hba.conf consistently
2. Use variables for IP ranges that may change
3. Document which applications need database access
4. Use least-privilege: specify exact databases and users, not "all"
