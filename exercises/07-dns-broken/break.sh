#!/bin/bash
# Exercise 07: DNS Resolution Failure
# This script breaks hostname resolution for the database

set -e

echo "Applying Exercise 07: DNS..."

docker exec backend bash -c '
    # Backup original hosts file
    cp /etc/hosts /etc/hosts.bak

    # Remove database entry from /etc/hosts
    grep -v "database" /etc/hosts > /tmp/hosts.new
    cp /tmp/hosts.new /etc/hosts

    # Add a wrong entry to make it more confusing
    echo "172.20.0.99 database-wrong" >> /etc/hosts

    echo "Break applied: database hostname cannot be resolved"
'

echo ""
echo "Exercise 07 applied!"
echo "The backend can no longer resolve the 'database' hostname."
echo ""
echo "Test with: curl http://localhost:8080/api/items"
echo "Or: make shell-backend && ping database"
