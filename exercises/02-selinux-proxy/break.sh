#!/bin/bash
# Exercise 02: SELinux Blocking Proxy
# Note: SELinux is tricky in containers. This exercise simulates the effect.

set -e

echo "Applying Exercise 02: SELinux Proxy..."

# In a real CentOS VM, we'd use: setsebool httpd_can_network_connect off
# In Docker, SELinux is typically disabled, so we simulate by blocking with iptables

docker exec frontend bash -c '
    # Simulate SELinux blocking by using iptables to block outgoing connections to backend
    # This mimics what would happen with httpd_can_network_connect=off

    # Block connections from httpd to backend:8080
    iptables -A OUTPUT -p tcp -d backend --dport 8080 -j REJECT 2>/dev/null || true

    # Create a fake audit log entry to simulate SELinux denial
    mkdir -p /var/log/audit
    echo "type=AVC msg=audit($(date +%s).123:456): avc:  denied  { name_connect } for  pid=$$ comm=\"httpd\" dest=8080 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:http_port_t:s0 tclass=tcp_socket permissive=0" >> /var/log/audit/audit.log

    echo "Break applied: Apache proxy should now fail with 503 errors"
'

echo ""
echo "Exercise 02 applied!"
echo "Test with:"
echo "  curl http://localhost:8080/        # Should work (static content)"
echo "  curl http://localhost:8080/health  # Should fail with 503"
echo ""
echo "Note: In a real VM, this would be an SELinux issue."
echo "In Docker, we simulate it with iptables."
echo ""
echo "To fix: Remove the iptables rule"
echo "  docker exec frontend iptables -D OUTPUT -p tcp -d backend --dport 8080 -j REJECT"
