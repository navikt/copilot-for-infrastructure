# Exercise 04: Systemd Service Won't Start

## Scenario

After a server reboot, the backend Java application won't start. The service script reports it's already running, but no Java process is found. Users are getting connection errors.

## Symptoms

```bash
# Try to access the API
curl http://localhost:8080/health
# Connection refused

# Check service status
make shell-backend
/etc/init.d/backend-app status
# Says "running" but nothing is actually running

# Try to start
/etc/init.d/backend-app start
# Says "already running"
```

## What to Investigate

1. **PID file**: Is there a stale PID file?
2. **Process check**: Is the process actually running?
3. **Service script**: How does it determine if the service is running?
4. **Logs**: What happened during the last start attempt?

## Useful Commands

```bash
# SSH into the backend container
make shell-backend

# Check the PID file
cat /var/run/app/backend.pid
ls -la /var/run/app/

# Is anything actually running?
ps aux | grep java
pgrep -f backend.jar

# Check if PID from file is valid
kill -0 $(cat /var/run/app/backend.pid) 2>&1

# Check the service script
cat /etc/init.d/backend-app

# Check application log
tail -50 /var/log/app/backend.log
```

## Hints

<details>
<summary>Hint 1</summary>
The service script uses a PID file to track whether the service is running. What happens if the PID file exists but the process doesn't?
</details>

<details>
<summary>Hint 2</summary>
Check if the process ID in the PID file corresponds to an actual running process.
</details>

<details>
<summary>Hint 3</summary>
Try removing the stale PID file, then starting the service again.
</details>

## Ask Copilot

Try asking Copilot:
- "What is a PID file and why do services use them?"
- "How do I check if a process with a specific PID is running?"
- "How do I fix a stale PID file issue?"
- "Write a robust bash function to check if a service is really running"
