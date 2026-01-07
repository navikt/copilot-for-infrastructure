# Solution: Exercise 04 - Systemd Service Won't Start

## Root Cause

A stale PID file exists at `/var/run/app/backend.pid` containing a PID that no longer corresponds to a running process. The service script checks for this file and assumes the service is running.

## Investigation Steps

### 1. Check service status

```bash
/etc/init.d/backend-app status
# Output: "backend-app is running (PID: 12345)"
```

### 2. Verify the PID file exists

```bash
cat /var/run/app/backend.pid
# Shows: 12345
```

### 3. Check if process actually exists

```bash
ps aux | grep 12345
# No output (process doesn't exist)

# Or check directly
kill -0 12345
# Output: No such process
```

### 4. Understand the problem

The PID file says process 12345 is running, but that process doesn't exist. This is a "stale PID file" - common after:
- System crash
- Process killed with SIGKILL
- Container restart

## The Fix

### Remove the stale PID file

```bash
rm /var/run/app/backend.pid
```

### Start the service

```bash
/etc/init.d/backend-app start
```

### Verify it's running

```bash
/etc/init.d/backend-app status
# Should show it's running

ps aux | grep backend.jar
# Should show the Java process

curl http://localhost:8080/health
# Should return 200 OK
```

## Understanding PID Files

PID files are used by init scripts to:
1. Track which process ID belongs to the service
2. Prevent multiple instances from starting
3. Enable graceful shutdown by knowing which process to signal

### The problem with PID files

They can become stale if the process exits abnormally without cleaning up.

### Better alternatives

1. **systemd native**: Uses cgroups to track processes, no PID files needed
2. **Process supervision**: Tools like supervisord, runit track processes directly
3. **Robust scripts**: Always verify PID is valid before trusting the file

## Improved Service Script

A more robust check:
```bash
status() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        # Verify process exists AND is our Java app
        if ps -p $PID -o comm= | grep -q java; then
            echo "$APP_NAME is running (PID: $PID)"
            return 0
        else
            echo "$APP_NAME PID file exists but process is not running (stale PID)"
            rm -f "$PID_FILE"  # Auto-cleanup
            return 1
        fi
    else
        echo "$APP_NAME is not running"
        return 1
    fi
}
```

## What Copilot Could Help With

1. **Understanding**: "What is a PID file and why do we use them?"
2. **Debugging**: "How do I check if a process is running by PID?"
3. **Improvement**: "Write a robust service script that handles stale PIDs"
4. **Best practices**: "Should I use PID files or systemd?"

## Prevention

1. Use systemd with `Type=simple` or `Type=exec` (no PID files needed)
2. Add cleanup logic to init scripts
3. Use process supervisors that handle this automatically
4. Configure proper shutdown hooks in the Java application
