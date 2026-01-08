#!/bin/bash
# Exercise 01: Apache 403 Forbidden
# This script breaks Apache by changing permissions and configuration

set -e

echo "Applying Exercise 01: Apache 403 Forbidden..."

# Execute commands in the frontend container
docker exec frontend bash -c '
    # Break 1: Change directory permissions to 700 (only root can access)
    chmod 700 /var/www/html

    # Break 2: Change Require directive to denied
    sed -i "s/Require all granted/Require all denied/g" /etc/httpd/conf.d/app.conf

    # Reload Apache to apply config changes (using SIGHUP since no systemd)
    pkill -HUP httpd || httpd -k graceful 2>/dev/null || true
    sleep 1

    echo "Break applied: Apache should now return 403 Forbidden"
'

echo ""
echo "Exercise 01 applied!"
echo "Test with: curl http://localhost:18080/"
echo "You should see a 403 Forbidden error."
echo ""
echo "SSH into frontend to investigate: make shell-frontend"
