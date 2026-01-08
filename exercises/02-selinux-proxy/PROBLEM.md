# Exercise 02: SELinux Blocking Proxy

## Scenario

The Apache reverse proxy was working yesterday, but now requests to `/health` and `/api/items` are failing with 503 errors. Static content at `/` works fine. A security patch was applied overnight that may have changed SELinux settings.

## Symptoms

```bash
# Static content works
curl http://localhost:18080/
# Returns: HTML page (200 OK)

# But API proxying fails
curl http://localhost:18080/health
# Returns: 503 Service Unavailable

curl http://localhost:18080/api/items
# Returns: 503 Service Unavailable
```

## What to Investigate

1. **Apache error logs**: What error is Apache logging?
2. **SELinux status**: Is SELinux enabled? What mode?
3. **SELinux audit logs**: Are there any AVC denials?
4. **SELinux booleans**: Are the right booleans enabled for proxying?

## Useful Commands

```bash
# SSH into the frontend container
make shell-frontend

# Check SELinux status
getenforce
sestatus

# Check Apache error log
tail -50 /var/log/httpd/error_log

# Check for SELinux denials
ausearch -m avc -ts recent
grep denied /var/log/audit/audit.log

# List SELinux booleans related to httpd
getsebool -a | grep httpd

# Check if httpd can make network connections
getsebool httpd_can_network_connect
```

## Hints

<details>
<summary>Hint 1</summary>
When Apache acts as a reverse proxy, it needs to make outbound network connections to the backend server.
</details>

<details>
<summary>Hint 2</summary>
SELinux has a boolean specifically for allowing httpd to make network connections: `httpd_can_network_connect`
</details>

<details>
<summary>Hint 3</summary>
Use `setsebool` to change SELinux booleans. Use the `-P` flag to make changes persistent.
</details>

## Ask Copilot

Try asking Copilot:
- "What is SELinux and what does enforcing mode mean?"
- "How do I allow Apache to make network connections with SELinux?"
- "Explain this AVC denial message: [paste the audit log]"
- "What does the httpd_can_network_connect boolean control?"
