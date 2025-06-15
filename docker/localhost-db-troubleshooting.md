# Localhost Database Connection Troubleshooting

If you're having trouble connecting to your local PostgreSQL database from Docker, follow these steps:

## Quick Diagnosis

1. **Check if PostgreSQL is running**:

   ```bash
   # macOS/Linux
   ps aux | grep postgres

   # Or check if port 5432 is listening
   lsof -i :5432
   ```

2. **Test connection from host machine**:
   ```bash
   psql -h localhost -p 5432 -U postgres -d mydb
   ```

## Common Solutions

### Solution 1: Configure PostgreSQL to Accept Docker Connections

PostgreSQL needs to be configured to accept connections from Docker containers.

**Edit `postgresql.conf`**:

```bash
# Find your PostgreSQL config file
sudo find /usr -name "postgresql.conf" 2>/dev/null
# Common locations:
# macOS (Homebrew): /usr/local/var/postgres/postgresql.conf
# Linux: /etc/postgresql/*/main/postgresql.conf
```

Add or modify this line:

```
listen_addresses = '*'
```

**Edit `pg_hba.conf`**:

```bash
# Find your pg_hba.conf file
sudo find /usr -name "pg_hba.conf" 2>/dev/null
```

Add this line to allow Docker network connections:

```
host    all             all             172.17.0.0/16           md5
```

**Restart PostgreSQL**:

```bash
# macOS (Homebrew)
brew services restart postgresql

# Linux (systemd)
sudo systemctl restart postgresql

# Linux (service)
sudo service postgresql restart
```

### Solution 2: Use Host Network Mode (Alternative)

If the above doesn't work, you can use host networking mode:

**Uncomment this line in docker-compose.yml**:

```yaml
network_mode: "host"
```

**Then rebuild and run**:

```bash
docker-compose down
docker-compose up --build
```

### Solution 3: Use Docker's PostgreSQL Service

Instead of connecting to host PostgreSQL, run PostgreSQL in Docker:

**Uncomment the postgres service in docker-compose.yml**:

```yaml
postgres:
  image: postgres:15-alpine
  # ... rest of the configuration
```

**Use this connection string**:

```
postgresql://postgres:password@postgres:5432/myapp
```

## Testing Your Setup

1. **Rebuild and run Docker**:

   ```bash
   docker-compose down
   docker-compose up --build
   ```

2. **Watch the logs** for multiple connection attempts:

   ```bash
   docker-compose logs -f backend
   ```

3. **You should see logs like**:
   ```
   [DatabaseService] Will try connection strategies:
   [DatabaseService] Attempting strategy 1/3
   [DatabaseService] Attempting strategy 2/3
   [DatabaseService] ✅ Connection successful with this strategy
   ```

## Still Having Issues?

1. **Check your local firewall** - it might be blocking Docker connections
2. **Try a different port** - maybe 5432 is blocked, try 5433
3. **Use an external database** - like Supabase or AWS RDS for development
4. **Check Docker logs** for specific error messages

## macOS Specific Notes

On macOS, you might need to use:

- `host.docker.internal` instead of `localhost`
- Check if PostgreSQL is installed via Homebrew: `brew services list | grep postgres`

## Linux Specific Notes

On Linux, Docker networking might behave differently:

- The host IP from container perspective might be `172.17.0.1`
- You might need to configure firewall rules: `sudo ufw allow from 172.17.0.0/16`
