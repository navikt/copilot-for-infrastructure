#!/bin/bash
# Exercise 04: Systemd Service Won't Start
# This script creates a stale PID file problem with a buggy init script

echo "Applying Exercise 04: Systemd Service..."

docker exec backend bash -c '
    # Stop the application if running
    /etc/init.d/backend-app stop 2>/dev/null || true
    sleep 1

    # Backup original script
    cp /etc/init.d/backend-app /etc/init.d/backend-app.bak

    # Create a buggy version that only checks PID file existence (not process)
    cat > /etc/init.d/backend-app << '\''SCRIPT'\''
#!/bin/bash
# chkconfig: 2345 95 05
# description: Backend Java Application (BUGGY VERSION)

APP_NAME="backend-app"
APP_JAR="/opt/app/backend.jar"
APP_USER="appuser"
PID_FILE="/var/run/app/backend.pid"
LOG_FILE="/var/log/app/backend.log"

JAVA_OPTS="${JAVA_OPTS:--Xms256m -Xmx512m}"
DB_HOST="${DB_HOST:-database}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-appdb}"
DB_USER="${DB_USER:-appuser}"
DB_PASSWORD="${DB_PASSWORD:-apppassword}"

start() {
    # BUG: Only checks if PID file exists, not if process is running!
    if [ -f "$PID_FILE" ]; then
        echo "$APP_NAME is already running"
        return 1
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
    echo "$APP_NAME started (PID: $!)"
}

stop() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        echo "Stopping $APP_NAME (PID: $PID)..."
        kill $PID 2>/dev/null || true
        rm -f $PID_FILE
        echo "$APP_NAME stopped"
    else
        echo "$APP_NAME is not running"
    fi
}

status() {
    # BUG: Only checks if PID file exists, not if process is running!
    if [ -f "$PID_FILE" ]; then
        echo "$APP_NAME is running (PID: $(cat $PID_FILE))"
        return 0
    else
        echo "$APP_NAME is not running"
        return 1
    fi
}

restart() { stop; sleep 1; start; }

case "$1" in
    start)   start ;;
    stop)    stop ;;
    restart) restart ;;
    status)  status ;;
    *)       echo "Usage: $0 {start|stop|restart|status}"; exit 1 ;;
esac
SCRIPT
    chmod +x /etc/init.d/backend-app

    # Stop using init script (avoids pkill issues)
    /etc/init.d/backend-app stop 2>/dev/null || true
    sleep 1

    # Create stale PID file
    mkdir -p /var/run/app
    echo "99999" > /var/run/app/backend.pid

    echo "Break applied: Stale PID file with buggy init script"
'

echo ""
echo "Exercise 04 applied!"
echo "The service thinks it's running but no process exists."
echo ""
echo "Test with:"
echo "  curl http://localhost:18080/health  # Will fail"
echo "  make shell-backend"
echo "  /etc/init.d/backend-app status     # Says running"
echo "  /etc/init.d/backend-app start      # Says already running"
