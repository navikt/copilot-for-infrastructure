# Exercise 01: Apache 403 Forbidden

## Scenario

Users are reporting that the website is returning "403 Forbidden" errors. The Apache web server is running, but something is preventing it from serving content.

## Symptoms

When you try to access the application:

```bash
curl http://localhost:8080/
```

You get a 403 Forbidden error instead of the expected web page.

## What to Investigate

1. **Apache error logs**: Check `/var/log/httpd/error_log` for clues
2. **File permissions**: Are the web files readable by Apache?
3. **Directory permissions**: Can Apache traverse to the document root?
4. **Apache configuration**: Check the `<Directory>` directives

## Useful Commands

```bash
# SSH into the frontend container
make shell-frontend

# Check Apache error log
tail -50 /var/log/httpd/error_log

# Check file permissions
ls -la /var/www/html/

# Check Apache configuration
cat /etc/httpd/conf.d/app.conf

# Test Apache configuration syntax
apachectl configtest

# Check what user Apache runs as
ps aux | grep httpd
```

## Hints

<details>
<summary>Hint 1</summary>
Look at the permissions on /var/www/html. What user does Apache run as?
</details>

<details>
<summary>Hint 2</summary>
The `Require` directive in Apache configuration controls access. Check if it's set correctly.
</details>

<details>
<summary>Hint 3</summary>
Use `ls -la` to check both file permissions AND directory permissions.
</details>

## Ask Copilot

Try asking Copilot these questions:
- "What does a 403 Forbidden error mean in Apache?"
- "How do I check Apache file permissions?"
- "What is the Require directive in Apache?"
- "Explain this Apache error log entry: [paste the error]"
