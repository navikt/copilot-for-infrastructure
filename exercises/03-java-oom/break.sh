#!/bin/bash
# Exercise 03: Java OutOfMemory Error
# This script configures the JVM with insufficient heap memory

set -e

echo "Applying Exercise 03: Java OOM..."

docker exec backend bash -c '
    # Stop the application first
    /etc/init.d/backend-app stop 2>/dev/null || true

    # Configure extremely small heap size
    cat > /opt/app/app.conf << EOF
# JVM Options - BROKEN: Heap too small!
JAVA_OPTS="-Xms16m -Xmx32m"

# Database connection settings
DB_HOST="database"
DB_PORT="5432"
DB_NAME="appdb"
DB_USER="appuser"
DB_PASSWORD="apppassword"

export JAVA_OPTS DB_HOST DB_PORT DB_NAME DB_USER DB_PASSWORD
EOF

    # Clean up any old PID files
    rm -f /var/run/app/backend.pid

    # Clear old logs
    > /var/log/app/backend.log

    # Try to start (it will likely crash)
    /etc/init.d/backend-app start || true

    echo "Break applied: JVM heap set to 32MB (way too small)"
'

echo ""
echo "Exercise 03 applied!"
echo "The application may crash repeatedly due to OutOfMemoryError."
echo ""
echo "Test with: curl http://localhost:8080/health"
echo "Check logs: make shell-backend && tail -f /var/log/app/backend.log"
