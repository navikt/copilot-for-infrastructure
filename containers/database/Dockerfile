# Database - PostgreSQL Server
# Using AlmaLinux 8 for better ARM64 support while maintaining RHEL compatibility
FROM almalinux:8

# Install PostgreSQL module and packages
RUN dnf install -y epel-release && \
    dnf module enable -y postgresql:13 && \
    dnf update -y && \
    dnf install -y \
        openssh-server openssh-clients \
        vim nano less which file tree \
        curl wget net-tools bind-utils tcpdump nmap-ncat telnet iproute iptables \
        htop sysstat iotop lsof strace \
        procps-ng psmisc \
        sudo passwd cronie rsync tar gzip unzip \
        # PostgreSQL 13
        postgresql-server \
        postgresql \
        postgresql-contrib \
    && dnf clean all

# Configure SSH
RUN ssh-keygen -A && \
    mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# Install node_exporter (architecture-aware)
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; elif [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi && \
    curl -LO https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-${ARCH}.tar.gz && \
    tar xzf node_exporter-1.6.1.linux-${ARCH}.tar.gz && \
    mv node_exporter-1.6.1.linux-${ARCH}/node_exporter /usr/local/bin/ && \
    rm -rf node_exporter-1.6.1.linux-${ARCH}* && \
    useradd -rs /bin/false node_exporter

# Set PostgreSQL environment
ENV PGDATA=/var/lib/pgsql/data
ENV PATH=/usr/bin:$PATH

# Initialize database manually (without systemd)
RUN mkdir -p /var/lib/pgsql/data && \
    chown -R postgres:postgres /var/lib/pgsql && \
    su - postgres -c "initdb -D /var/lib/pgsql/data"

# Configure PostgreSQL
RUN echo "listen_addresses = '*'" >> /var/lib/pgsql/data/postgresql.conf && \
    echo "port = 5432" >> /var/lib/pgsql/data/postgresql.conf && \
    echo "max_connections = 100" >> /var/lib/pgsql/data/postgresql.conf && \
    echo "log_destination = 'stderr'" >> /var/lib/pgsql/data/postgresql.conf && \
    echo "logging_collector = on" >> /var/lib/pgsql/data/postgresql.conf && \
    echo "log_directory = 'log'" >> /var/lib/pgsql/data/postgresql.conf && \
    echo "log_filename = 'postgresql-%Y-%m-%d.log'" >> /var/lib/pgsql/data/postgresql.conf

# Configure pg_hba.conf for authentication
RUN echo "# TYPE  DATABASE        USER            ADDRESS                 METHOD" > /var/lib/pgsql/data/pg_hba.conf && \
    echo "local   all             all                                     peer" >> /var/lib/pgsql/data/pg_hba.conf && \
    echo "host    all             all             127.0.0.1/32            md5" >> /var/lib/pgsql/data/pg_hba.conf && \
    echo "host    all             all             ::1/128                 md5" >> /var/lib/pgsql/data/pg_hba.conf && \
    echo "# Allow connections from Docker network" >> /var/lib/pgsql/data/pg_hba.conf && \
    echo "host    all             all             172.21.0.0/16           md5" >> /var/lib/pgsql/data/pg_hba.conf && \
    chown postgres:postgres /var/lib/pgsql/data/pg_hba.conf

# Create init script for database setup
RUN mkdir -p /docker-entrypoint-initdb.d && \
    cat > /docker-entrypoint-initdb.d/init.sql << 'EOF'
-- Create application user and database
CREATE USER appuser WITH PASSWORD 'apppassword';
CREATE DATABASE appdb OWNER appuser;

\c appdb

-- Create tables
CREATE TABLE items (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO items (name, description) VALUES
    ('Server Alpha', 'Primary application server - RHEL 8'),
    ('Server Beta', 'Secondary application server - RHEL 8'),
    ('Database Primary', 'PostgreSQL primary node'),
    ('Database Replica', 'PostgreSQL read replica'),
    ('Load Balancer', 'HAProxy load balancer'),
    ('Monitoring', 'Prometheus + Grafana stack'),
    ('Jump Host', 'SSH bastion host'),
    ('Backup Server', 'Backup and disaster recovery');

-- Grant permissions
GRANT ALL PRIVILEGES ON DATABASE appdb TO appuser;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO appuser;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO appuser;
EOF
RUN chown postgres:postgres /docker-entrypoint-initdb.d/init.sql

# Create entrypoint script
RUN cat > /entrypoint.sh << 'EOF'
#!/bin/bash
set -e

# Start SSH daemon
/usr/sbin/sshd

# Start node_exporter
/usr/local/bin/node_exporter --web.listen-address=:9100 &

# Ensure proper ownership of data directory
chown -R postgres:postgres /var/lib/pgsql/data

# Create log directory if it doesn't exist
mkdir -p /var/lib/pgsql/data/log
chown postgres:postgres /var/lib/pgsql/data/log

# Start PostgreSQL
echo "Starting PostgreSQL..."
su - postgres -c "pg_ctl start -D /var/lib/pgsql/data -l /var/lib/pgsql/data/log/startup.log -w"

# Run init script if database needs initialization
if [ -f /docker-entrypoint-initdb.d/init.sql ]; then
    # Check if appdb exists
    if ! su - postgres -c "psql -lqt | cut -d \| -f 1 | grep -qw appdb"; then
        echo "Initializing database..."
        su - postgres -c "psql -f /docker-entrypoint-initdb.d/init.sql"
        echo "Database initialized!"
    fi
fi

echo "PostgreSQL is ready!"

# Keep container running and tail logs
tail -f /var/lib/pgsql/data/log/*.log 2>/dev/null || tail -f /dev/null
EOF
RUN chmod +x /entrypoint.sh

# Add helpful aliases
RUN echo 'alias ll="ls -la"' >> /root/.bashrc && \
    echo 'alias la="ls -la"' >> /root/.bashrc && \
    echo 'alias ports="ss -tlnp"' >> /root/.bashrc && \
    echo 'alias pglogs="tail -f /var/lib/pgsql/data/log/*.log"' >> /root/.bashrc && \
    echo 'alias psql="sudo -u postgres psql"' >> /root/.bashrc && \
    echo 'alias pgctl="sudo -u postgres pg_ctl"' >> /root/.bashrc

EXPOSE 22 5432 9100

ENTRYPOINT ["/entrypoint.sh"]
