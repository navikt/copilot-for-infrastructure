# Solution: Exercise 01 - Apache 403 Forbidden

## Root Cause

The break script did two things:
1. Changed `/var/www/html` permissions to `700` (only root can access)
2. Changed the `Require` directive from `Require all granted` to `Require all denied`

## Investigation Steps

### 1. Check the Apache error log

```bash
tail -50 /var/log/httpd/error_log
```

You should see entries like:
```
[authz_core:error] [pid 123] [client 172.20.0.1:54321] AH01630: client denied by server configuration: /var/www/html/
```

### 2. Check directory permissions

```bash
ls -la /var/www/
```

You'll see:
```
drwx------  2 root root 4096 Jan  6 12:00 html
```

The `700` permission means only root can read/write/execute. Apache runs as the `apache` user.

### 3. Check Apache configuration

```bash
cat /etc/httpd/conf.d/app.conf
```

Look for:
```apache
<Directory /var/www/html>
    ...
    Require all denied
</Directory>
```

## The Fix

### Fix 1: Restore directory permissions

```bash
chmod 755 /var/www/html
chown apache:apache /var/www/html
```

### Fix 2: Fix Apache configuration

Edit `/etc/httpd/conf.d/app.conf` and change:
```apache
Require all denied
```
to:
```apache
Require all granted
```

### Fix 3: Restart Apache

```bash
apachectl graceful
```

Or:
```bash
systemctl reload httpd
```

## Verify the Fix

```bash
curl http://localhost:8080/
```

You should now see the welcome page.

## What Copilot Could Help With

1. **Explaining the error**: "What does AH01630 mean in Apache?"
2. **Permission syntax**: "What do the numbers 755 mean for file permissions?"
3. **Apache directives**: "Explain the Require directive in Apache 2.4"
4. **Commands**: "How do I change file ownership in Linux?"

## Prevention

In a real environment, you would:
1. Use Ansible to manage Apache configuration consistently
2. Set up monitoring alerts for 4xx/5xx error spikes
3. Use configuration management to enforce correct permissions
