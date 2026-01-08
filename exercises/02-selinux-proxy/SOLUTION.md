# Solution: Exercise 02 - SELinux Blocking Proxy

## Root Cause

The SELinux boolean `httpd_can_network_connect` was set to `off`, preventing Apache from making outbound network connections to the backend server.

## Investigation Steps

### 1. Check Apache error log

```bash
tail -50 /var/log/httpd/error_log
```

You should see entries like:
```
[proxy:error] [pid 123] (13)Permission denied: AH00957: HTTP: attempt to connect to 172.21.0.11:8080 (backend) failed
[proxy_http:error] [pid 123] [client 172.21.0.1:54321] AH01114: HTTP: failed to make connection to backend (backend)
```

### 2. Check SELinux status

```bash
getenforce
# Returns: Enforcing

sestatus
# Shows SELinux is enabled and enforcing
```

### 3. Check for AVC denials

```bash
ausearch -m avc -ts recent
# or
grep denied /var/log/audit/audit.log | tail -10
```

You'll see something like:
```
type=AVC msg=audit(...): avc:  denied  { name_connect } for  pid=123 comm="httpd" dest=8080 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:http_port_t:s0 tclass=tcp_socket
```

### 4. Check the SELinux boolean

```bash
getsebool httpd_can_network_connect
# Returns: httpd_can_network_connect --> off
```

## The Fix

### Enable the SELinux boolean

```bash
# Temporarily (until reboot)
setsebool httpd_can_network_connect on

# Permanently (survives reboot)
setsebool -P httpd_can_network_connect on
```

### Verify the fix

```bash
getsebool httpd_can_network_connect
# Returns: httpd_can_network_connect --> on

curl http://localhost:18080/health
# Should now return 200 OK
```

## Understanding the Fix

SELinux restricts what processes can do based on their security context. The `httpd_t` context (which Apache runs under) is not allowed to make outbound network connections by default.

The `httpd_can_network_connect` boolean specifically allows:
- Apache to connect to any TCP port
- This is necessary for reverse proxy functionality

## What Copilot Could Help With

1. **Understanding SELinux**: "What is SELinux and how does it work?"
2. **Interpreting audit logs**: "What does this AVC denial mean?"
3. **Finding solutions**: "How do I allow Apache to connect to backend servers with SELinux?"
4. **Best practices**: "Is enabling httpd_can_network_connect secure?"

## Prevention

In a real environment:
1. Include SELinux configuration in your Ansible playbooks
2. Document required SELinux booleans for each service
3. Test SELinux settings as part of deployment
4. Consider using `audit2allow` for complex scenarios
