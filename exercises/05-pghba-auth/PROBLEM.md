# Exercise 05: PostgreSQL Authentication Failure

## Scenario

The backend application can't connect to the database. Developers confirm the credentials are correct in the application config. The database server is running and accepting connections locally.

## Symptoms

```bash
# API returns database error
curl http://localhost:18080/api/items
# {"error": "Database error", "message": "...authentication failed..."}

# Health check shows database down
curl http://localhost:18080/health
# {"status": "unhealthy", "database": {"status": "down"}}

# But database is running!
make shell-database
sudo -u postgres psql -c "SELECT 1"
# Works fine
```

## What to Investigate

1. **pg_hba.conf**: PostgreSQL's host-based authentication config
2. **Client IP address**: What IP is the backend connecting from?
3. **PostgreSQL logs**: What does the server say about failed connections?
4. **Network connectivity**: Can the backend reach the database port?

## Useful Commands

```bash
# SSH into database container
make shell-database

# Check PostgreSQL is running
ps aux | grep postgres
ss -tlnp | grep 5432

# Check PostgreSQL logs
tail -50 /var/lib/pgsql/data/log/*.log

# View pg_hba.conf
cat /var/lib/pgsql/data/pg_hba.conf

# Test local connection
sudo -u postgres psql -c "SELECT 1"
PGPASSWORD=apppassword psql -h 127.0.0.1 -U appuser -d appdb -c "SELECT 1"

# Check what IPs can connect
# From backend container:
make shell-backend
hostname -I
nc -zv database 5432
```

## Hints

<details>
<summary>Hint 1</summary>
pg_hba.conf controls which hosts can connect to PostgreSQL and how they authenticate.
</details>

<details>
<summary>Hint 2</summary>
Check the IP address/subnet configured in pg_hba.conf. Does it include the backend's IP?
</details>

<details>
<summary>Hint 3</summary>
Look at the PostgreSQL log for the exact error message. It will tell you what IP address is being rejected.
</details>

## Ask Copilot

Try asking Copilot:
- "Explain the pg_hba.conf file format"
- "What does 'no pg_hba.conf entry for host' mean?"
- "How do I allow a specific IP to connect to PostgreSQL?"
- "What authentication methods are available in pg_hba.conf?"
