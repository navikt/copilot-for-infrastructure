#!/bin/bash
# Exercise 07: DNS Resolution Failure
# This script breaks hostname resolution by changing the DB_HOST config

echo "Applying Exercise 07: DNS..."

docker exec backend bash -c '
    # Stop the backend app
    /etc/init.d/backend-app stop 2>/dev/null || true
    sleep 1
    rm -f /var/run/app/backend.pid

    # Backup original init script
    cp /etc/init.d/backend-app /etc/init.d/backend-app.bak 2>/dev/null || true

    # Change DB_HOST variable assignment to a non-existent hostname
    # Only target the line starting with DB_HOST=
    sed -i "s/^DB_HOST=.*/DB_HOST=\"database-server.corp.local\"/" /etc/init.d/backend-app

    # Start with wrong hostname
    /etc/init.d/backend-app start

    echo "Break applied: Backend now tries to connect to non-existent hostname"
'

echo ""
echo "Exercise 07 applied!"
echo "The backend is now configured with wrong database hostname."
echo ""
echo "Test with: curl http://localhost:18080/api/items"
echo "Check logs: make shell-backend && cat /var/log/app/backend.log"
echo ""
echo "Note: The fix is to correct DB_HOST in /etc/init.d/backend-app"
