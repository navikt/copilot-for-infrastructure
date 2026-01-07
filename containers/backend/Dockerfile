# Backend - Java Application Server
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
        # Java 8
        java-1.8.0-openjdk \
        java-1.8.0-openjdk-devel \
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

# Set JAVA_HOME
ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
ENV PATH=$JAVA_HOME/bin:$PATH

# Create application directory
RUN mkdir -p /opt/app && \
    useradd -r -s /bin/false appuser && \
    chown appuser:appuser /opt/app

# Create application directories for logs and PID
RUN mkdir -p /var/log/app /var/run/app && \
    chown appuser:appuser /var/log/app /var/run/app

# Create systemd-like service script for the Java app
RUN cat > /etc/init.d/backend-app << 'EOF'
#!/bin/bash
# chkconfig: 2345 95 05
# description: Backend Java Application

APP_NAME="backend-app"
APP_JAR="/opt/app/backend.jar"
APP_USER="appuser"
PID_FILE="/var/run/app/backend.pid"
LOG_FILE="/var/log/app/backend.log"

# Default JVM options (can be overridden by environment)
JAVA_OPTS="${JAVA_OPTS:--Xms256m -Xmx512m}"

# Database connection settings
DB_HOST="${DB_HOST:-database}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-appdb}"
DB_USER="${DB_USER:-appuser}"
DB_PASSWORD="${DB_PASSWORD:-apppassword}"

start() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p $PID > /dev/null 2>&1; then
            echo "$APP_NAME is already running (PID: $PID)"
            return 1
        fi
    fi

    echo "Starting $APP_NAME..."
    cd /opt/app

    nohup java $JAVA_OPTS \
        -DDB_HOST=$DB_HOST \
        -DDB_PORT=$DB_PORT \
        -DDB_NAME=$DB_NAME \
        -DDB_USER=$DB_USER \
        -DDB_PASSWORD=$DB_PASSWORD \
        -jar $APP_JAR >> $LOG_FILE 2>&1 &

    echo $! > $PID_FILE
    echo "$APP_NAME started (PID: $(cat $PID_FILE))"
}

stop() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        echo "Stopping $APP_NAME (PID: $PID)..."
        kill $PID 2>/dev/null
        rm -f $PID_FILE
        echo "$APP_NAME stopped"
    else
        echo "$APP_NAME is not running"
    fi
}

restart() {
    stop
    sleep 2
    start
}

status() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p $PID > /dev/null 2>&1; then
            echo "$APP_NAME is running (PID: $PID)"
            return 0
        else
            echo "$APP_NAME PID file exists but process is not running"
            return 1
        fi
    else
        echo "$APP_NAME is not running"
        return 1
    fi
}

case "$1" in
    start)   start ;;
    stop)    stop ;;
    restart) restart ;;
    status)  status ;;
    *)       echo "Usage: $0 {start|stop|restart|status}" ;;
esac
EOF
RUN chmod +x /etc/init.d/backend-app

# Create entrypoint script
RUN cat > /entrypoint.sh << 'EOF'
#!/bin/bash
set -e

# Start SSH daemon
/usr/sbin/sshd

# Start node_exporter
/usr/local/bin/node_exporter --web.listen-address=:9100 &

# Wait for database to be ready
echo "Waiting for database..."
for i in {1..30}; do
    if nc -z ${DB_HOST:-database} ${DB_PORT:-5432} 2>/dev/null; then
        echo "Database is ready!"
        break
    fi
    echo "Waiting for database... ($i/30)"
    sleep 2
done

# Start the Java application
if [ -f /opt/app/backend.jar ]; then
    echo "Starting backend application..."
    /etc/init.d/backend-app start
else
    echo "Warning: /opt/app/backend.jar not found"
    echo "The application will need to be deployed via Ansible"
fi

# Keep container running
tail -f /var/log/app/backend.log 2>/dev/null || tail -f /dev/null
EOF
RUN chmod +x /entrypoint.sh

# Add helpful aliases
RUN echo 'alias ll="ls -la"' >> /root/.bashrc && \
    echo 'alias la="ls -la"' >> /root/.bashrc && \
    echo 'alias ports="ss -tlnp"' >> /root/.bashrc && \
    echo 'alias applogs="tail -f /var/log/app/backend.log"' >> /root/.bashrc && \
    echo 'alias appstart="/etc/init.d/backend-app start"' >> /root/.bashrc && \
    echo 'alias appstop="/etc/init.d/backend-app stop"' >> /root/.bashrc && \
    echo 'alias appstatus="/etc/init.d/backend-app status"' >> /root/.bashrc && \
    echo 'alias jps="jps -v"' >> /root/.bashrc

EXPOSE 22 8080 9100

ENTRYPOINT ["/entrypoint.sh"]
