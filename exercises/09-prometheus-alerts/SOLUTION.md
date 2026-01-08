# Solution: Exercise 09 - Prometheus Metrics Investigation

## The Problem

The node_exporter process on one of the servers was stopped, causing Prometheus to report the target as "down".

## Investigation Steps

1. **Check Prometheus targets**:
   ```bash
   curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, instance: .labels.instance, health: .health}'
   ```

2. **Identify the down target**:
   ```bash
   curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.health != "up")'
   ```

3. **Check the error message** - likely "connection refused" or "context deadline exceeded"

4. **Verify node_exporter is not running**:
   ```bash
   docker exec backend ps aux | grep node_exporter
   # No output = not running
   ```

## The Fix

Start node_exporter on the affected server:

```bash
docker exec backend /usr/local/bin/node_exporter &
```

Or restart it properly:
```bash
docker exec backend pkill -f node_exporter
docker exec backend nohup /usr/local/bin/node_exporter > /var/log/node_exporter.log 2>&1 &
```

## Verification

Wait 15-30 seconds for Prometheus to scrape again, then check:

```bash
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, instance: .labels.instance, health: .health}'
# All should show "up"
```

## Root Cause

The node_exporter process was killed or crashed. In production, you would:
1. Set up node_exporter as a systemd service with auto-restart
2. Configure alerting to notify when targets go down
3. Investigate why the process died (OOM killer, manual kill, crash)
