# Solution: Exercise 10 - Log Analysis

## The Problem

The application logs contain ERROR messages about database connection pool exhaustion. The connection pool was misconfigured with too few connections, causing timeouts under load.

## Investigation Steps

1. **Search for errors**:
   ```bash
   grep -i error /var/log/app/backend.log
   ```

2. **Look at error details**:
   ```bash
   grep -B2 -A2 "ERROR" /var/log/app/backend.log
   ```

3. **Identify the pattern** - Errors mention:
   - "Connection pool exhausted"
   - "Timeout waiting for connection"
   - "Max pool size: 2"

4. **Find the configuration issue**:
   The logs show the connection pool is limited to 2 connections, which is too few for the application's needs.

## The Fix

The issue is in the database connection configuration. The connection pool size needs to be increased.

Check the current configuration:
```bash
grep -i "pool\|connection" /opt/app/app.conf
# Or check environment variables
env | grep DB
```

Fix by increasing the pool size (the actual fix depends on how the app is configured).

In this exercise, the logs reveal the problem - you don't necessarily need to fix it, just identify it from the logs.

## Verification

After identifying the issue, you can verify by:
1. Recognizing the error pattern in the logs
2. Understanding that "pool exhausted" with "max size: 2" is the root cause
3. Knowing that increasing `DB_POOL_SIZE` or similar config would fix it

## Key Log Analysis Techniques Used

1. `grep -i error` - Case-insensitive search for errors
2. `grep -B2 -A2` - Show context around matches
3. Pattern recognition - Multiple errors with same message
4. Reading the actual error message - It tells you exactly what's wrong

## Root Cause

Database connection pool was configured with only 2 connections. Under concurrent load, connections are exhausted and requests fail. The fix is to increase pool size to match expected concurrency.
