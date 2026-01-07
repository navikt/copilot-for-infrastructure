# Frontend - Apache Web Server / Reverse Proxy
# Using AlmaLinux 8 for better ARM64 support while maintaining RHEL compatibility
FROM almalinux:8

# Install EPEL and common tools
RUN dnf install -y epel-release && \
    dnf update -y && \
    dnf install -y \
        openssh-server openssh-clients \
        vim nano less which file tree \
        curl wget net-tools bind-utils tcpdump nmap-ncat telnet iproute iptables \
        htop sysstat iotop lsof strace \
        procps-ng psmisc \
        sudo passwd cronie rsync tar gzip unzip \
        # Apache and modules
        httpd \
        mod_ssl \
        # SELinux tools
        policycoreutils-python-utils \
        setools-console \
    && dnf clean all

# Configure SSH
RUN ssh-keygen -A && \
    mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh && \
    sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# Install node_exporter (architecture-aware)
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; elif [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi && \
    curl -LO https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-${ARCH}.tar.gz && \
    tar xzf node_exporter-1.6.1.linux-${ARCH}.tar.gz && \
    mv node_exporter-1.6.1.linux-${ARCH}/node_exporter /usr/local/bin/ && \
    rm -rf node_exporter-1.6.1.linux-${ARCH}* && \
    useradd -rs /bin/false node_exporter

# Configure Apache
RUN mkdir -p /var/www/html/app && \
    chown -R apache:apache /var/www/html && \
    # Disable default SSL configuration (we're not using HTTPS in this demo)
    rm -f /etc/httpd/conf.d/ssl.conf

# Create Apache VirtualHost configuration for reverse proxy
RUN cat > /etc/httpd/conf.d/app.conf << 'EOF'
<VirtualHost *:80>
    ServerName frontend
    DocumentRoot /var/www/html

    # Health check endpoint
    <Location /health>
        ProxyPass http://backend:8080/health
        ProxyPassReverse http://backend:8080/health
    </Location>

    # API endpoints - proxy to backend
    <Location /api>
        ProxyPass http://backend:8080/api
        ProxyPassReverse http://backend:8080/api
    </Location>

    # Static files
    <Directory /var/www/html>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    # Logging
    ErrorLog /var/log/httpd/app_error.log
    CustomLog /var/log/httpd/app_access.log combined
</VirtualHost>
EOF

# Create a simple index page
RUN cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Copilot Infrastructure Demo</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { background: white; padding: 30px; border-radius: 8px; max-width: 600px; margin: 0 auto; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #333; }
        .status { padding: 10px; margin: 10px 0; border-radius: 4px; }
        .ok { background: #d4edda; color: #155724; }
        .error { background: #f8d7da; color: #721c24; }
        a { color: #007bff; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🖥️ Infrastructure Demo</h1>
        <p>Welcome to the Copilot for Infrastructure training environment.</p>

        <h2>Quick Links</h2>
        <ul>
            <li><a href="/health">Health Check</a></li>
            <li><a href="/api/items">API Items</a></li>
        </ul>

        <h2>Architecture</h2>
        <p>Frontend (Apache) → Backend (Java) → Database (PostgreSQL)</p>

        <h2>Monitoring</h2>
        <p>Prometheus: <a href="http://localhost:9090">http://localhost:9090</a></p>
    </div>
</body>
</html>
EOF

# Create entrypoint script
RUN cat > /entrypoint.sh << 'EOF'
#!/bin/bash
set -e

# Start SSH daemon
/usr/sbin/sshd

# Start node_exporter
/usr/local/bin/node_exporter --web.listen-address=:9100 &

# Start Apache in foreground
exec /usr/sbin/httpd -DFOREGROUND
EOF
RUN chmod +x /entrypoint.sh

# Add helpful aliases
RUN echo 'alias ll="ls -la"' >> /root/.bashrc && \
    echo 'alias la="ls -la"' >> /root/.bashrc && \
    echo 'alias ports="ss -tlnp"' >> /root/.bashrc && \
    echo 'alias httpdlogs="tail -f /var/log/httpd/*.log"' >> /root/.bashrc && \
    echo 'alias apachectl="apachectl"' >> /root/.bashrc

EXPOSE 22 80 443 9100

ENTRYPOINT ["/entrypoint.sh"]
