#!/bin/bash
# Exercise 06: Firewall Blocking Database
# Note: In containers, we simulate firewall by changing PostgreSQL listen config

echo "Applying Exercise 06: Firewall..."

docker exec database bash -c '
    # Backup original postgresql.conf
    cp /var/lib/pgsql/data/postgresql.conf /var/lib/pgsql/data/postgresql.conf.bak

    # Change listen_addresses to only localhost (simulates firewall blocking)
    sed -i "s/listen_addresses = .*/listen_addresses = '\''127.0.0.1'\''/" /var/lib/pgsql/data/postgresql.conf

    # Reload PostgreSQL to apply changes (reload is sufficient for listen_addresses after restart)
    # But listen_addresses requires restart, so we stop and start
    su - postgres -c "pg_ctl stop -D /var/lib/pgsql/data -m fast -w -t 10" 2>/dev/null || true
    sleep 2
    su - postgres -c "pg_ctl start -D /var/lib/pgsql/data -l /var/lib/pgsql/data/log/startup.log -w -t 10" 2>/dev/null || true
    sleep 1

    # Create fake iptables rule info for the exercise
    echo "# Simulated firewall rule (iptables not available in container)" > /tmp/firewall_rules.txt
    echo "Chain INPUT (policy ACCEPT)" >> /tmp/firewall_rules.txt
    echo "target     prot opt source               destination" >> /tmp/firewall_rules.txt
    echo "REJECT     tcp  --  172.21.0.0/16        0.0.0.0/0            tcp dpt:5432 reject-with icmp-port-unreachable" >> /tmp/firewall_rules.txt

    echo "Break applied: PostgreSQL now only listens on localhost (simulates firewall)"
'

echo ""
echo "Exercise 06 applied!"
echo "The database now only accepts local connections."
echo ""
echo "Test with: curl http://localhost:8080/api/items"
echo "Or from backend: make shell-backend && nc -zv database 5432"
echo ""
echo "Note: In a real VM, this would be an iptables/firewalld issue."
echo "In Docker, we simulate by changing PostgreSQL listen_addresses."
