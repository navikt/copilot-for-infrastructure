# Exercise 03: Java OutOfMemory Error

## Scenario

The backend Java application keeps crashing and restarting. Users are experiencing intermittent failures when accessing the API. The operations team suspects a memory leak.

## Symptoms

```bash
# Health check sometimes works, sometimes fails
curl http://localhost:8080/health
# Intermittent: 200 OK or connection refused

# Check if backend is running
make shell-backend
/etc/init.d/backend-app status
# Shows process keeps restarting
```

## What to Investigate

1. **Application logs**: Check for OutOfMemoryError
2. **JVM settings**: What heap size is configured?
3. **System logs**: Is OOM killer involved?
4. **Process monitoring**: Memory usage over time

## Useful Commands

```bash
# SSH into the backend container
make shell-backend

# Check application logs
tail -100 /var/log/app/backend.log

# Check JVM configuration
cat /opt/app/app.conf

# Check running Java processes and their flags
ps aux | grep java
jps -v

# Check system memory
free -h
cat /proc/meminfo

# Check for OOM killer activity
dmesg | grep -i "out of memory"
dmesg | grep -i "killed process"

# Monitor Java process memory (if running)
top -p $(pgrep -f backend.jar)
```

## Hints

<details>
<summary>Hint 1</summary>
Look at the `-Xmx` flag in the Java startup command. This controls maximum heap size.
</details>

<details>
<summary>Hint 2</summary>
The application log should show `java.lang.OutOfMemoryError: Java heap space`
</details>

<details>
<summary>Hint 3</summary>
Edit `/opt/app/app.conf` to change JAVA_OPTS, then restart the service.
</details>

## Ask Copilot

Try asking Copilot:
- "What does java.lang.OutOfMemoryError: Java heap space mean?"
- "What JVM flags control heap memory?"
- "How do I increase Java heap size?"
- "What's the difference between -Xms and -Xmx?"
- "How do I diagnose Java memory issues?"
