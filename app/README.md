# Backend Application

A minimal Java 8 HTTP server that connects to PostgreSQL.

## Endpoints

- `GET /` - API info
- `GET /health` - Health check (includes database connectivity)
- `GET /api/items` - List items from database

## Building

```bash
./build.sh
```

This will:
1. Download the PostgreSQL JDBC driver
2. Compile the Java source
3. Create a fat JAR with all dependencies

## Running

```bash
java -jar backend.jar
```

### Configuration

The application reads configuration from system properties or environment variables:

| Property    | Default     | Description         |
| ----------- | ----------- | ------------------- |
| DB_HOST     | database    | PostgreSQL hostname |
| DB_PORT     | 5432        | PostgreSQL port     |
| DB_NAME     | appdb       | Database name       |
| DB_USER     | appuser     | Database user       |
| DB_PASSWORD | apppassword | Database password   |

Example with custom settings:
```bash
java -DDB_HOST=localhost -DDB_PORT=5432 -jar backend.jar
```

## JVM Tuning

For production-like settings:
```bash
java -Xms256m -Xmx512m -XX:+UseG1GC -jar backend.jar
```
