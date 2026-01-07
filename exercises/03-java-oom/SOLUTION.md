# Solution: Exercise 03 - Java OutOfMemory Error

## Root Cause

The JVM heap was configured with `-Xmx32m` (32 megabytes), which is far too small for the application. When the application tries to allocate more memory than available, it crashes with OutOfMemoryError.

## Investigation Steps

### 1. Check application logs

```bash
tail -100 /var/log/app/backend.log
```

You should see:
```
Exception in thread "main" java.lang.OutOfMemoryError: Java heap space
    at java.util.Arrays.copyOf(Arrays.java:3210)
    ...
```

### 2. Check current JVM configuration

```bash
cat /opt/app/app.conf
```

You'll see:
```
JAVA_OPTS="-Xms16m -Xmx32m"
```

### 3. Check running process (if it's currently up)

```bash
ps aux | grep java
# or
jps -v
```

Shows the tiny heap settings.

### 4. Check for OOM killer

```bash
dmesg | grep -i "killed"
```

May show the kernel OOM killer terminating the process.

## The Fix

### Edit the JVM configuration

```bash
vi /opt/app/app.conf
```

Change:
```bash
JAVA_OPTS="-Xms16m -Xmx32m"
```

To something reasonable:
```bash
JAVA_OPTS="-Xms256m -Xmx512m"
```

### Restart the application

```bash
/etc/init.d/backend-app restart
```

### Verify the fix

```bash
# Check it's running
/etc/init.d/backend-app status

# Check the JVM flags
ps aux | grep java

# Test the endpoint
curl http://localhost:8080/health
```

## Understanding JVM Memory

| Flag                   | Meaning                                |
| ---------------------- | -------------------------------------- |
| `-Xms`                 | Initial heap size (starting memory)    |
| `-Xmx`                 | Maximum heap size (memory ceiling)     |
| `-XX:MetaspaceSize`    | Initial metaspace (for class metadata) |
| `-XX:MaxMetaspaceSize` | Maximum metaspace                      |

### Recommended Settings

For a container with 2GB RAM:
```bash
JAVA_OPTS="-Xms256m -Xmx512m -XX:+UseG1GC"
```

Rule of thumb: Leave headroom for the OS and native memory:
- Container: 2GB
- Heap: 512MB-1GB
- Remaining: OS, native memory, thread stacks

## What Copilot Could Help With

1. **Error explanation**: "What causes OutOfMemoryError: Java heap space?"
2. **JVM tuning**: "What are recommended JVM memory settings?"
3. **Monitoring**: "How do I monitor Java heap usage?"
4. **GC tuning**: "What garbage collector should I use for Java 8?"

## Prevention

1. Set appropriate memory limits in configuration management
2. Monitor JVM metrics (expose via JMX or Micrometer)
3. Set up alerts for high heap usage before OOM
4. Use `-XX:+HeapDumpOnOutOfMemoryError` to capture heap dumps
5. Consider container-aware JVM flags: `-XX:+UseContainerSupport`
