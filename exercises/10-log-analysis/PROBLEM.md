# Exercise 10: Log Analysis - Finding the Needle

## Scenario

Users are reporting intermittent errors when using the application. The errors happen randomly and are hard to reproduce. The development team says "it works on my machine" and asks you to find evidence in the logs. You need to search through application logs to find error patterns and identify the root cause.

## Symptoms

```bash
# Sometimes requests fail
curl http://localhost:8080/api/items
# Occasionally returns: {"error": "Internal server error", "message": "..."}

# Health check usually passes
curl http://localhost:8080/health
# Usually returns healthy, but sometimes shows issues
```

## What to Investigate

1. **Application logs**: Search for ERROR and WARN messages
2. **Log timestamps**: When do errors occur? Any patterns?
3. **Error types**: What kinds of errors are being logged?
4. **Stack traces**: What's causing the exceptions?
5. **Correlation**: Do errors correlate with specific actions?

## Useful Commands

```bash
# SSH into backend container
make shell-backend

# View recent application logs
tail -100 /var/log/app/backend.log

# Search for errors in logs
grep -i "error\|exception\|failed" /var/log/app/backend.log

# Count errors by type
grep -i error /var/log/app/backend.log | sort | uniq -c | sort -rn

# Find errors with context (3 lines before and after)
grep -B3 -A3 "ERROR" /var/log/app/backend.log

# Search for specific time range
grep "2026-01-07 10:" /var/log/app/backend.log

# Watch logs in real-time
tail -f /var/log/app/backend.log

# Search across multiple log files
find /var/log -name "*.log" -exec grep -l "error" {} \;

# Use awk to extract specific fields
awk '/ERROR/ {print $1, $2, $NF}' /var/log/app/backend.log

# Count errors per hour
grep ERROR /var/log/app/backend.log | cut -d' ' -f1-2 | cut -d':' -f1 | uniq -c
```

## Log Format

The application logs use this format:
```
TIMESTAMP LEVEL [THREAD] CLASS - MESSAGE
2026-01-07 10:23:45.123 ERROR [http-8080-1] DatabasePool - Connection timeout after 30000ms
```

## Hints

<details>
<summary>Hint 1</summary>
Start with `grep -i error /var/log/app/backend.log` to see all error messages. Look for patterns.
</details>

<details>
<summary>Hint 2</summary>
The errors mention a specific component or resource. Check if that resource is properly configured.
</details>

<details>
<summary>Hint 3</summary>
Look at the timestamps - errors might cluster around certain times, indicating a timeout or connection issue.
</details>

<details>
<summary>Hint 4</summary>
The error messages mention connection pool exhaustion. Check database connection settings.
</details>

## Ask Copilot

Try asking Copilot:
- "How do I search for errors in Linux log files?"
- "Explain this Java stack trace: [paste the trace]"
- "What does 'connection pool exhausted' mean?"
- "How do I filter logs by timestamp using grep?"
- "Write a command to count error types in a log file"
- "What grep options help me see context around matches?"

## Log Analysis Tips

1. **Start broad, then narrow**: First get an overview, then dig into specifics
2. **Look for patterns**: Errors often repeat with similar messages
3. **Check timestamps**: Timing can reveal the cause (e.g., timeout issues)
4. **Read error messages carefully**: They often tell you exactly what's wrong
5. **Context matters**: Use `-B` and `-A` flags with grep to see surrounding lines
