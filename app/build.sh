#!/bin/bash
# Build script for the backend application
# Compiles the Java source and packages it with the PostgreSQL driver

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Building Backend Application..."

# Create build directories
mkdir -p build/classes
mkdir -p lib

# Download PostgreSQL JDBC driver if not present
PG_JAR="lib/postgresql-42.6.0.jar"
if [ ! -f "$PG_JAR" ]; then
    echo "Downloading PostgreSQL JDBC driver..."
    curl -L -o "$PG_JAR" \
        "https://jdbc.postgresql.org/download/postgresql-42.6.0.jar"
fi

# Compile Java source
echo "Compiling Java source..."
javac -source 1.8 -target 1.8 \
    -cp "$PG_JAR" \
    -d build/classes \
    src/main/java/com/example/backend/BackendApp.java

# Create manifest
echo "Creating manifest..."
cat > build/MANIFEST.MF << EOF
Manifest-Version: 1.0
Main-Class: com.example.backend.BackendApp
Class-Path: lib/postgresql-42.6.0.jar
EOF

# Package as JAR
echo "Creating backend.jar..."
cd build/classes
jar cfm ../../backend.jar ../MANIFEST.MF com/

cd "$SCRIPT_DIR"

# Create a fat JAR (include PostgreSQL driver)
echo "Creating fat JAR with dependencies..."
mkdir -p build/fatjar
cd build/fatjar

# Extract PostgreSQL driver
jar xf ../../lib/postgresql-42.6.0.jar

# Copy our classes
cp -r ../classes/com .

# Remove signature files from PostgreSQL driver
rm -rf META-INF/*.SF META-INF/*.DSA META-INF/*.RSA 2>/dev/null || true

# Create manifest for fat jar
cat > META-INF/MANIFEST.MF << EOF
Manifest-Version: 1.0
Main-Class: com.example.backend.BackendApp
EOF

# Create the fat jar
jar cfm ../../backend.jar META-INF/MANIFEST.MF .

cd "$SCRIPT_DIR"
rm -rf build

echo ""
echo "Build complete: backend.jar"
echo "Run with: java -jar backend.jar"
