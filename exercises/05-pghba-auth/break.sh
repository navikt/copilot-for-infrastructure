#!/bin/bash
# Exercise 05: PostgreSQL Authentication Failure
# This script breaks pg_hba.conf to reject backend connections

echo "Applying Exercise 05: PostgreSQL Auth..."

docker exec database bash -c '
    # Backup original
    cp /var/lib/pgsql/data/pg_hba.conf /var/lib/pgsql/data/pg_hba.conf.bak

    # Create broken pg_hba.conf with wrong IP range
    cat > /var/lib/pgsql/data/pg_hba.conf << EOF
# PostgreSQL Client Authentication Configuration File
# BROKEN: Only allows connections from 172.21.0.99 (wrong IP!)

# Local connections (these still work)
local   all             all                                     peer
local   all             postgres                                peer

# IPv4 local connections
host    all             all             127.0.0.1/32            md5

# Docker network - WRONG! Only allows 172.21.0.99 (old network)
host    all             all             172.21.0.99/32          md5
EOF

    chown postgres:postgres /var/lib/pgsql/data/pg_hba.conf
    chmod 600 /var/lib/pgsql/data/pg_hba.conf

    # Reload PostgreSQL
    su - postgres -c "pg_ctl reload -D /var/lib/pgsql/data"

    echo "Break applied: pg_hba.conf now rejects backend connections"
'

echo ""
echo "Exercise 05 applied!"
echo "The backend can no longer connect to the database."
echo ""
echo "Test with: curl http://localhost:18080/api/items"
echo "You should see a database authentication error."
echo ""
echo "Hint: The backend IP is 172.21.0.11"
