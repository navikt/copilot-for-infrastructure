#!/bin/bash
# Exercise 02: SELinux Blocking Proxy
# Note: SELinux is tricky in containers. This exercise simulates the effect.

set -e

echo "Applying Exercise 02: SELinux Proxy..."

# In a real CentOS/RHEL VM, we'd use: setsebool httpd_can_network_connect off
# In Docker, SELinux is typically disabled, so we simulate by breaking the proxy config

docker exec frontend bash -c '
    # Simulate SELinux blocking by changing proxy to unreachable port
    # This mimics what would happen with httpd_can_network_connect=off
    sed -i "s/backend:8080/backend:9999/g" /etc/httpd/conf.d/app.conf

    # Create a fake audit log entry to simulate SELinux denial
    mkdir -p /var/log/audit
    echo "type=AVC msg=audit($(date +%s).123:456): avc:  denied  { name_connect } for  pid=$$ comm=\"httpd\" dest=8080 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:http_port_t:s0 tclass=tcp_socket permissive=0" >> /var/log/audit/audit.log

    # Reload Apache
    pkill -HUP httpd || true
    sleep 1

    echo "Break applied: Apache proxy should now fail with 503 errors"
'

echo ""
echo "Exercise 02 applied!"
echo "Test with:"
echo "  curl http://localhost:18080/        # Should work (static content)"
echo "  curl http://localhost:18080/health  # Should fail with 503"
echo ""
echo "Note: In a real VM, this would be an SELinux issue."
echo "In Docker, we simulate it by breaking the proxy target."
echo ""
echo "SSH into frontend to investigate: make shell-frontend"
