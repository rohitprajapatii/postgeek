# Universal Database Connection Guide

This application supports **dynamic database connections** that work across all systems and setups. Users can connect to any PostgreSQL database through the dashboard interface.

## 🌍 Universal Compatibility

### ✅ Supported Database Types

- **Local PostgreSQL** (localhost, 127.0.0.1)
- **External Cloud Databases** (Supabase, AWS RDS, Google Cloud SQL, etc.)
- **Remote PostgreSQL servers** (any network-accessible PostgreSQL)
- **Containerized databases** (Docker, Kubernetes)

### ✅ Supported Systems

- **macOS** (Intel & Apple Silicon)
- **Linux** (Ubuntu, CentOS, Debian, etc.)
- **Windows** (with WSL2)
- **Docker environments** (all platforms)

## 🚀 Quick Start

### 1. Run the Application

```bash
# Using Docker (recommended for production)
docker-compose up --build

# Using npm (for development)
cd backend && npm run start:dev
```

### 2. Connect via Dashboard

Open your dashboard and use any of these connection string formats:

**Local PostgreSQL:**

```
postgresql://username:password@localhost:5432/database_name
```

**External Databases:**

```
# Supabase
postgresql://postgres:your_password@db.your_project.supabase.co:5432/postgres

# AWS RDS
postgresql://username:password@your-db.region.rds.amazonaws.com:5432/database

# Any external PostgreSQL
postgresql://user:pass@your-server.com:5432/dbname
```

## 🔧 How It Works

### Docker Networking

- **Host Network Mode**: For localhost database access
- **Automatic Detection**: Distinguishes between local and external connections
- **Smart Configuration**: Optimizes connection settings based on database type

### Connection Intelligence

- **Local Databases**: Uses shorter timeouts, no SSL by default
- **External Databases**: Uses longer timeouts, supports SSL, keep-alive connections
- **Error Guidance**: Provides specific troubleshooting for different error types

## 📋 Connection Examples

### Local Development Databases

**PostgreSQL on macOS (Homebrew):**

```
postgresql://postgres:@localhost:5432/your_database
```

**PostgreSQL on Linux:**

```
postgresql://postgres:password@localhost:5432/your_database
```

**PostgreSQL with custom port:**

```
postgresql://user:password@localhost:5433/database
```

### Cloud Database Services

**Supabase:**

```
postgresql://postgres:[YOUR-PASSWORD]@db.[YOUR-PROJECT-REF].supabase.co:5432/postgres
```

**AWS RDS:**

```
postgresql://[username]:[password]@[endpoint]:5432/[database-name]
```

**Google Cloud SQL:**

```
postgresql://[username]:[password]@[public-ip]:5432/[database-name]
```

**DigitalOcean Managed Database:**

```
postgresql://[username]:[password]@[hostname]:25060/[database]?sslmode=require
```

## 🛠️ Troubleshooting

The application provides detailed error messages and guidance. Common issues:

### "Connection Refused"

- **Local**: Ensure PostgreSQL is running and listening on the correct port
- **External**: Check firewall settings and database server status

### "Host Not Found"

- **Local**: Verify PostgreSQL service is started
- **External**: Check hostname/URL and internet connectivity

### "Authentication Failed"

- Verify username and password
- Check user permissions in the database

### "Database Does Not Exist"

- Confirm database name is correct
- Ensure the database exists on the server

## 🐳 Docker-Specific Notes

### Host Networking Mode

The application uses host networking mode to access localhost databases seamlessly. This means:

- ✅ Direct access to localhost PostgreSQL
- ✅ Works across all operating systems
- ✅ No complex network configuration needed

### Port Considerations

When running in Docker:

- Frontend: `http://localhost:8081`
- Backend API: `http://localhost:3000`
- Local PostgreSQL: `localhost:5432` (works directly)

## 🔐 Security Best Practices

### For Production

1. **Use SSL connections** for external databases
2. **Rotate passwords** regularly
3. **Use least-privilege** database users
4. **Network security** - restrict database access by IP when possible

### Connection String Security

- Never log complete connection strings
- The application automatically masks passwords in logs
- Store sensitive credentials securely

## 🧪 Testing Your Setup

### Test Local Connection

```bash
# Test if PostgreSQL is accessible
psql -h localhost -p 5432 -U your_user -d your_database
```

### Test Docker Setup

```bash
# Check container status
docker-compose ps

# View application logs
docker-compose logs -f backend

# Test database connection from container
docker exec -it project-backend-1 sh
```

## 📞 Support

### Connection Logs

The application provides detailed connection logs including:

- Connection type detection (local vs external)
- SSL configuration status
- Performance metrics
- Detailed error messages with specific guidance

### Common Connection Strings

Keep these templates handy for quick setup:

```bash
# Local (no password)
postgresql://postgres:@localhost:5432/mydb

# Local (with password)
postgresql://postgres:mypassword@localhost:5432/mydb

# External (with SSL)
postgresql://user:pass@external-host.com:5432/db?sslmode=require

# External (without SSL)
postgresql://user:pass@external-host.com:5432/db
```

## 🎯 Universal Design Goals

This system is designed to:

- ✅ Work out-of-the-box on any system
- ✅ Require zero configuration for end users
- ✅ Support any PostgreSQL database setup
- ✅ Provide clear error messages and guidance
- ✅ Handle both development and production environments
- ✅ Scale from single-user to enterprise deployments

The application automatically handles all the complexity of Docker networking, SSL configuration, and connection optimization, so users can focus on their data instead of configuration!
