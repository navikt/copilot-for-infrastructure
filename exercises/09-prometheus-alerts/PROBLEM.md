# Exercise 09: Prometheus Metrics Investigation

## Scenario

The monitoring team has reported that Prometheus shows one of the application servers as "down" in the targets list. However, users aren't complaining about any issues. You need to investigate whether this is a real problem or a monitoring configuration issue.

## Symptoms

```bash
# Check Prometheus targets
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, instance: .labels.instance, health: .health}'

# One of the node_exporter targets shows as "down"

# But the application seems to work fine
curl http://localhost:8080/health
# Returns healthy
```

## What to Investigate

1. **Prometheus targets**: Which target is down? What's the error?
2. **Target endpoint**: Can you manually reach the metrics endpoint?
3. **Prometheus config**: Is the scrape target configured correctly?
4. **Network**: Can Prometheus reach the target?

## Useful Commands

```bash
# Check Prometheus targets via API
curl -s http://localhost:9090/api/v1/targets | jq .

# Check specific target health
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.health != "up")'

# Access Prometheus UI
open http://localhost:9090/targets

# Check node_exporter directly from containers
docker exec frontend curl -s http://localhost:9100/metrics | head -20
docker exec backend curl -s http://localhost:9100/metrics | head -20
docker exec database curl -s http://localhost:9100/metrics | head -20

# Check Prometheus config
docker exec prometheus cat /etc/prometheus/prometheus.yml

# Check if node_exporter is running
docker exec frontend ps aux | grep node_exporter
docker exec backend ps aux | grep node_exporter
docker exec database ps aux | grep node_exporter

# Test connectivity from Prometheus container
docker exec prometheus wget -q -O- http://frontend:9100/metrics | head -5
docker exec prometheus wget -q -O- http://backend:9100/metrics | head -5
docker exec prometheus wget -q -O- http://database:9100/metrics | head -5
```

## Hints

<details>
<summary>Hint 1</summary>
Use `curl http://localhost:9090/api/v1/targets` to see all targets and their status. Look for any that show health: "down".
</details>

<details>
<summary>Hint 2</summary>
The lastError field in the target info will tell you why Prometheus can't scrape the target.
</details>

<details>
<summary>Hint 3</summary>
Check if the node_exporter process is actually running on the affected host. If not, you need to start it.
</details>

## Ask Copilot

Try asking Copilot:
- "How do I query Prometheus targets via the API?"
- "What does 'context deadline exceeded' mean in Prometheus?"
- "How do I check if node_exporter is running?"
- "Explain the Prometheus scrape configuration format"
- "How do I troubleshoot Prometheus target scraping issues?"

## Prometheus Basics

Prometheus scrapes metrics from targets at regular intervals. Each target exposes metrics on an HTTP endpoint (usually `/metrics`). If Prometheus can't reach the endpoint, the target shows as "down".

Key concepts:
- **Target**: An endpoint that Prometheus scrapes
- **Scrape interval**: How often Prometheus collects metrics (default 15s)
- **node_exporter**: Exports system metrics (CPU, memory, disk, network)
