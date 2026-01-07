#!/bin/bash
# Exercise 04: Systemd Service Won't Start
# This script creates a stale PID file problem

set -e

echo "Applying Exercise 04: Systemd Service..."

docker exec backend bash -c '
    # Stop the application if running
    /etc/init.d/backend-app stop 2>/dev/null || true

    # Make sure process is really dead
    pkill -f backend.jar 2>/dev/null || true
    sleep 2

    # Create a stale PID file with a non-existent PID
    mkdir -p /var/run/app
    echo "99999" > /var/run/app/backend.pid

    echo "Break applied: Stale PID file created"
'

echo ""
echo "Exercise 04 applied!"
echo "The service thinks it's running but no process exists."
echo ""
echo "Test with:"
echo "  curl http://localhost:8080/health  # Will fail"
echo "  make shell-backend"
echo "  /etc/init.d/backend-app status     # Says running"
echo "  /etc/init.d/backend-app start      # Says already running"
