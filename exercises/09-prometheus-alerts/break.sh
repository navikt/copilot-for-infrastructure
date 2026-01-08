#!/bin/bash
# Exercise 09: Prometheus Metrics Investigation
# This script stops node_exporter on one of the servers

echo "Applying Exercise 09: Prometheus Target Down..."

# Stop node_exporter on the backend server
docker exec backend pkill -f node_exporter 2>/dev/null || true

echo ""
echo "Exercise 09 applied!"
echo "One of the Prometheus targets is now down."
echo ""
echo "Investigate with:"
echo "  curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job, instance: .labels.instance, health}'"
echo ""
echo "Or open Prometheus UI: http://localhost:9090/targets"
echo ""
echo "Note: It may take 15-30 seconds for Prometheus to detect the target is down."
