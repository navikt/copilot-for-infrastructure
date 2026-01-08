#!/bin/bash
# Exercise 10: Log Analysis - Finding the Needle
# This script adds realistic error logs to the application log file

echo "Applying Exercise 10: Log Analysis..."

docker exec backend bash -c '
    LOG_FILE="/var/log/app/backend.log"

    # Get current timestamp base
    BASE_TIME=$(date +%Y-%m-%d)

    # Add realistic error logs mixed with normal operation logs
    cat >> $LOG_FILE << EOF

${BASE_TIME} 09:15:23.456 INFO  [main] Application - Backend application starting...
${BASE_TIME} 09:15:24.789 INFO  [main] DatabasePool - Initializing connection pool (max size: 2)
${BASE_TIME} 09:15:25.123 INFO  [main] Application - Server started on port 8080
${BASE_TIME} 09:23:45.234 INFO  [http-8080-1] ItemController - GET /api/items - 200 OK (45ms)
${BASE_TIME} 09:24:12.567 INFO  [http-8080-2] HealthController - GET /health - 200 OK (12ms)
${BASE_TIME} 09:31:45.890 WARN  [http-8080-1] DatabasePool - Connection pool utilization high: 2/2 (100%)
${BASE_TIME} 09:31:46.123 ERROR [http-8080-3] DatabasePool - Connection pool exhausted! Max pool size: 2, waiting threads: 1
${BASE_TIME} 09:31:46.124 ERROR [http-8080-3] ItemController - Failed to fetch items: Timeout waiting for database connection
java.sql.SQLException: Cannot acquire connection from pool - pool exhausted
    at com.corp.db.ConnectionPool.getConnection(ConnectionPool.java:142)
    at com.corp.backend.ItemController.getItems(ItemController.java:58)
    at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
    at com.sun.net.httpserver.ServerImpl.handle(ServerImpl.java:298)
${BASE_TIME} 09:32:15.456 INFO  [http-8080-1] ItemController - GET /api/items - 200 OK (38ms)
${BASE_TIME} 09:45:23.789 INFO  [http-8080-2] HealthController - GET /health - 200 OK (8ms)
${BASE_TIME} 09:52:34.012 WARN  [http-8080-1] DatabasePool - Connection pool utilization high: 2/2 (100%)
${BASE_TIME} 09:52:34.345 WARN  [http-8080-2] DatabasePool - Connection checkout taking longer than expected: 2500ms
${BASE_TIME} 09:52:35.678 ERROR [http-8080-3] DatabasePool - Connection pool exhausted! Max pool size: 2, waiting threads: 3
${BASE_TIME} 09:52:35.679 ERROR [http-8080-3] ItemController - Failed to fetch items: Timeout waiting for database connection
java.sql.SQLException: Cannot acquire connection from pool - pool exhausted
    at com.corp.db.ConnectionPool.getConnection(ConnectionPool.java:142)
    at com.corp.backend.ItemController.getItems(ItemController.java:58)
    at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
${BASE_TIME} 09:52:35.680 ERROR [http-8080-4] DatabasePool - Connection pool exhausted! Max pool size: 2, waiting threads: 2
${BASE_TIME} 09:52:36.012 INFO  [http-8080-1] ItemController - GET /api/items - 200 OK (156ms)
${BASE_TIME} 10:05:12.345 INFO  [http-8080-2] HealthController - GET /health - 200 OK (15ms)
${BASE_TIME} 10:12:45.678 INFO  [http-8080-1] ItemController - GET /api/items - 200 OK (42ms)
${BASE_TIME} 10:23:56.901 WARN  [http-8080-1] DatabasePool - Connection pool utilization high: 2/2 (100%)
${BASE_TIME} 10:23:57.234 ERROR [http-8080-2] DatabasePool - Connection pool exhausted! Max pool size: 2, waiting threads: 2
${BASE_TIME} 10:23:57.235 ERROR [http-8080-2] ItemController - Request failed after 30000ms timeout
java.util.concurrent.TimeoutException: Timed out waiting for database connection
    at com.corp.db.ConnectionPool.getConnection(ConnectionPool.java:156)
    at com.corp.backend.ItemController.getItems(ItemController.java:58)
${BASE_TIME} 10:24:15.567 INFO  [http-8080-1] ItemController - GET /api/items - 200 OK (89ms)
${BASE_TIME} 10:35:23.890 INFO  [http-8080-2] HealthController - GET /health - 200 OK (11ms)
EOF

    echo "Added realistic error logs to $LOG_FILE"
'

echo ""
echo "Exercise 10 applied!"
echo "Error logs have been added to the application log file."
echo ""
echo "Your task: Find and analyze the errors in the logs."
echo ""
echo "Start with:"
echo "  make shell-backend"
echo "  grep -i error /var/log/app/backend.log"
echo ""
echo "Tips:"
echo "  - Look for ERROR and WARN messages"
echo "  - Note the timestamps and patterns"
echo "  - Read the stack traces carefully"
echo "  - What resource is being exhausted?"
