# Solution: Exercise 06 - Firewall Blocking Database

## Root Cause

An iptables rule was added to the database server that rejects incoming connections on port 5432 from the backend's IP range.

## Investigation Steps

### 1. Test network connectivity

```bash
# From backend container
nc -zv database 5432
# Connection refused
```

### 2. Check iptables rules on database

```bash
# On database container
iptables -L INPUT -n -v
```

You should see:
```
Chain INPUT (policy ACCEPT)
pkts bytes target     prot opt in     out     source               destination
   0     0 REJECT     tcp  --  *      *       172.20.0.0/16        0.0.0.0/0    tcp dpt:5432 reject-with icmp-port-unreachable
```

### 3. Confirm PostgreSQL is listening

```bash
ss -tlnp | grep 5432
# Shows: LISTEN  0  128  0.0.0.0:5432
```

PostgreSQL is listening correctly - the firewall is blocking.

## The Fix

### Option 1: Remove the blocking rule

```bash
# Find and remove the specific rule
iptables -D INPUT -p tcp -s 172.20.0.0/16 --dport 5432 -j REJECT
```

### Option 2: Add an ACCEPT rule before the REJECT

```bash
# Accept PostgreSQL from backend
iptables -I INPUT 1 -p tcp -s 172.20.0.11 --dport 5432 -j ACCEPT
```

### Option 3: Flush all rules (use carefully!)

```bash
iptables -F
```

### Verify the fix

```bash
# From backend
nc -zv database 5432
# Connection succeeded

# Test the API
curl http://localhost:8080/api/items
```

## Understanding iptables

### Chain types

| Chain   | Purpose                         |
| ------- | ------------------------------- |
| INPUT   | Traffic coming INTO the server  |
| OUTPUT  | Traffic going OUT of the server |
| FORWARD | Traffic being routed through    |

### Rule targets

| Target | Action                 |
| ------ | ---------------------- |
| ACCEPT | Allow the packet       |
| DROP   | Silently discard       |
| REJECT | Discard and send error |

### Rule matching order

Rules are evaluated top to bottom. First match wins!

```bash
# List with line numbers
iptables -L INPUT -n --line-numbers

# Insert at specific position
iptables -I INPUT 1 -p tcp --dport 5432 -j ACCEPT

# Append at end
iptables -A INPUT -p tcp --dport 5432 -j ACCEPT
```

## Production-safe firewall management

```bash
# Allow PostgreSQL from specific subnet
iptables -I INPUT -p tcp -s 172.20.0.0/16 --dport 5432 -j ACCEPT

# Save rules (CentOS/RHEL)
iptables-save > /etc/sysconfig/iptables

# Or use firewalld
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="172.20.0.0/16" port port="5432" protocol="tcp" accept'
firewall-cmd --reload
```

## What Copilot Could Help With

1. **Syntax**: "How do I write an iptables rule to allow port 5432?"
2. **Debugging**: "How do I see which iptables rule is blocking my traffic?"
3. **Best practices**: "What's the right way to configure PostgreSQL firewall rules?"
4. **Comparison**: "What's the difference between iptables and firewalld?"

## Prevention

1. Use configuration management (Ansible) for firewall rules
2. Document required ports for each service
3. Test firewall changes in staging first
4. Use firewalld zones for easier management
5. Always have out-of-band access before changing firewall rules
