#!/bin/bash
# Exercise 06: Firewall Blocking Database
# This script adds an iptables rule blocking PostgreSQL

set -e

echo "Applying Exercise 06: Firewall..."

docker exec database bash -c '
    # Add iptables rule to block PostgreSQL port from Docker network
    iptables -I INPUT -p tcp -s 172.20.0.0/16 --dport 5432 -j REJECT 2>/dev/null || true

    echo "Break applied: Firewall now blocks port 5432 from backend"
'

echo ""
echo "Exercise 06 applied!"
echo "The database firewall now blocks incoming connections."
echo ""
echo "Test with: curl http://localhost:8080/api/items"
echo "Or from backend: make shell-backend && nc -zv database 5432"
