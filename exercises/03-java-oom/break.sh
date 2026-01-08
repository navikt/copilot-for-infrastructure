#!/bin/bash
# Exercise 03: Java OutOfMemory Error
# This script simulates a JVM with insufficient heap memory

set -e

echo "Applying Exercise 03: Java OOM..."

docker exec backend bash -c '
    # Stop the application first
    /etc/init.d/backend-app stop 2>/dev/null || true
    sleep 1

    # Clean up any old PID files
    rm -f /var/run/app/backend.pid

    # Modify the init script to use tiny heap (backup first)
    cp /etc/init.d/backend-app /etc/init.d/backend-app.bak
    sed -i "s/JAVA_OPTS=\"\${JAVA_OPTS:--Xms256m -Xmx512m}\"/JAVA_OPTS=\"-Xms4m -Xmx8m\"/" /etc/init.d/backend-app

    # Add OOM error to log to simulate the problem
    cat >> /var/log/app/backend.log << EOF
Exception in thread "main" java.lang.OutOfMemoryError: Java heap space
	at java.util.Arrays.copyOf(Arrays.java:3210)
	at java.util.ArrayList.grow(ArrayList.java:265)
	at java.util.ArrayList.ensureExplicitCapacity(ArrayList.java:239)
	at java.util.ArrayList.ensureCapacityInternal(ArrayList.java:231)
	at java.util.ArrayList.add(ArrayList.java:462)
	at com.corp.backend.Application.loadData(Application.java:142)
	at com.corp.backend.Application.main(Application.java:58)

JVM heap exhausted. Current settings: -Xms4m -Xmx8m
Application terminated due to insufficient memory.
EOF

    echo ""
    echo "Note: In this demo, the app is too small to actually OOM."
    echo "Check /var/log/app/backend.log to see simulated OOM error."
    echo "The fix is still to increase -Xmx in /etc/init.d/backend-app"
'

# Restart the app (it will work, but the exercise is about finding/fixing the config)
docker exec backend /etc/init.d/backend-app start 2>/dev/null || true

echo ""
echo "Exercise 03 applied!"
echo "Check the logs for OutOfMemoryError messages."
echo ""
echo "Test with: curl http://localhost:18080/health"
echo "Check logs: make shell-backend && cat /var/log/app/backend.log"
