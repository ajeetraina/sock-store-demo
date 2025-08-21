# 🔧 Troubleshooting Guide

Common issues and solutions for the Docker MCP Gateway Interceptor Demo.

## 🚨 "Model Too Big" Error

**Error:** `unable to load runner: model too big`

**Cause:** The Qwen3:14B-Q6_K model requires more VRAM than available.

**Solutions:**

### Option 1: Use OpenAI API (Recommended)
```bash
# Stop current stack
docker compose down

# Ensure you have OpenAI API key
echo "sk-your-openai-key-here" > secret.openai-api-key

# Start with OpenAI configuration (default)
docker compose up --build -d
```

### Option 2: Use Smaller Local Model
```bash
# Stop current stack
docker compose down

# Use Phi3-mini (only 2GB VRAM needed)
docker compose -f compose.yaml -f compose.local-model.yaml up --build -d
```

### Option 3: Check System Resources
```bash
# Check available VRAM (if you have GPU)
nvidia-smi

# Check Docker resources
docker system df
docker system prune -f  # Clean up if needed
```

## 💻 UI Content Structure Errors

**Error:** `KeyError: 'content'`

**Cause:** Message parsing issues in Streamlit interface when model fails.

**Solution:**
```bash
# Restart the UI services
docker compose restart adk adk-ui

# Check ADK service logs
docker compose logs adk

# If still failing, switch to OpenAI API
docker compose down
docker compose up --build -d
```

## 🔗 Network Connection Issues

**Error:** Services can't connect to each other

**Solution:**
```bash
# Check if all services are on same network
docker network ls
docker network inspect sock-store-demo_default

# Restart the stack
docker compose down
docker compose up --build -d
```

## 📝 Missing Interceptor Logs

**Issue:** No logs appearing in `/var/log/mcp-interceptors.log`

**Cause:** Interceptors only create logs when tools are actually called.

**Solution:**
```bash
# Check if interceptors are mounted
docker compose exec mcp-gateway ls -la /interceptors/

# Verify interceptors are executable
docker compose exec mcp-gateway find /interceptors -name "*.sh" -executable

# Make interceptors executable if needed
chmod +x interceptors/*.sh
docker compose restart mcp-gateway

# Test by using the Agent Portal
# Visit http://localhost:3000 and submit a vendor request
```

## 🔑 Missing API Keys

**Error:** Authentication failures or missing environment variables

**Solution:**
```bash
# Check if secrets are properly set
docker compose exec mcp-gateway env | grep -E "(BRAVE|RESEND|OPENAI)"

# Recreate secrets
export BRAVE_API_KEY=<your_key>
export RESEND_API_KEY=<your_key>
export OPENAI_API_KEY=<your_key>
make gateway-secrets

# Restart services
docker compose restart mcp-gateway adk
```

## 📱 Port Conflicts

**Error:** Port already in use

**Solution:**
```bash
# Check what's using the ports
lsof -i :3000  # Agent Portal
lsof -i :8090  # Interceptor Dashboard
lsof -i :8811  # MCP Gateway
lsof -i :9090  # Sock Store

# Either stop conflicting services or change ports in compose.yaml
# Example: Change port 3000 to 3001
ports:
  - "3001:3000"
```

## 🐳 Docker Issues

### Disk Space
```bash
# Check Docker disk usage
docker system df

# Clean up unused resources
docker system prune -a -f
docker volume prune -f
```

### Memory Issues
```bash
# Check Docker memory usage
docker stats

# Increase Docker Desktop memory allocation
# Docker Desktop → Settings → Resources → Memory
```

### Permission Issues
```bash
# Fix file permissions
sudo chown -R $USER:$USER .
chmod +x demo-interceptors.sh
chmod +x interceptors/*.sh
```

## 🔍 Debugging Commands

### Check Service Health
```bash
# Overview of all services
docker compose ps

# Detailed service status
docker compose top

# Service resource usage
docker stats $(docker compose ps -q)
```

### View Logs
```bash
# All services
docker compose logs

# Specific service
docker compose logs mcp-gateway
docker compose logs adk

# Follow logs in real-time
docker compose logs -f mcp-gateway
```

### Interactive Debugging
```bash
# Execute commands in running containers
docker compose exec mcp-gateway bash
docker compose exec adk bash

# Check file contents
docker compose exec mcp-gateway cat /var/log/mcp-interceptors.log
docker compose exec mcp-gateway ls -la /interceptors/
```

## 🧪 Test Interceptors Manually

### Test Secret Detection
```bash
# This should be blocked
echo '{"method": "search", "params": {"query": "api_key=sk-1234567890abcdef1234567890abcdef12345"}}' | \
docker compose exec -T mcp-gateway /interceptors/secret_detector.sh
```

### Test Business Logic
```bash
# This should be rejected (price too low)
echo '{"vendor": "TestVendor", "product": "cheap socks", "price": "$2.99"}' | \
docker compose exec -T mcp-gateway /interceptors/sock_store_business.sh
```

### Test Content Filter
```bash
# This should filter competitor names
echo '{"result": "These socks are better than adidas products"}' | \
docker compose exec -T mcp-gateway /interceptors/content_filter.sh
```

## 🆘 Last Resort: Complete Reset

If all else fails:

```bash
# Stop everything
docker compose down -v

# Remove all containers and volumes
docker compose rm -f
docker volume rm sock-store-demo_mongodb_data sock-store-demo_mcp_logs

# Clean up Docker
docker system prune -a -f

# Recreate secrets
make gateway-secrets

# Start fresh
docker compose up --build -d

# Wait and test
sleep 30
./demo-interceptors.sh
```

## 📞 Getting Help

1. **Check the logs first:**
   ```bash
   docker compose logs > debug-logs.txt
   ```

2. **Verify your environment:**
   ```bash
   docker --version
   docker compose version
   echo $DOCKER_DEFAULT_PLATFORM
   ```

3. **Create a GitHub issue** with:
   - Your operating system
   - Docker version
   - Error messages
   - Output of `docker compose ps`

Remember: The interceptor framework is designed to be resilient. Even if some services have issues, the interceptors should still be operational and logging activity!
