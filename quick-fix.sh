#!/bin/bash

# Quick Fix Script for Common Issues
# Run this if you're experiencing "model too big" or other startup issues

set -e

echo "🔧 Docker MCP Gateway Interceptor Demo - Quick Fix"
echo "================================================"
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}📍 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if we're in the right directory
if [ ! -f "compose.yaml" ]; then
    print_error "compose.yaml not found. Please run this script from the sock-store-demo directory."
    exit 1
fi

# Check if on interceptor-demo branch
current_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
if [ "$current_branch" != "interceptor-demo" ]; then
    print_warning "Not on interceptor-demo branch. Switching..."
    git checkout interceptor-demo
fi

print_step "Stopping any running services..."
docker compose down -v 2>/dev/null || true

print_step "Cleaning up Docker resources..."
docker system prune -f >/dev/null 2>&1 || true

print_step "Making interceptor scripts executable..."
chmod +x interceptors/*.sh 2>/dev/null || true
chmod +x demo-interceptors.sh 2>/dev/null || true

print_step "Checking for required API keys..."

# Check if OpenAI API key exists
if [ ! -f "secret.openai-api-key" ] || [ ! -s "secret.openai-api-key" ]; then
    if [ -n "$OPENAI_API_KEY" ]; then
        echo "$OPENAI_API_KEY" > secret.openai-api-key
        print_success "Created OpenAI API key file from environment variable"
    else
        print_warning "OpenAI API key not found. Please set OPENAI_API_KEY environment variable"
        echo "Example: export OPENAI_API_KEY=sk-your-key-here"
        echo "Then run: echo \$OPENAI_API_KEY > secret.openai-api-key"
        echo
    fi
fi

# Check if MCP secrets exist
if [ ! -f ".mcp.env" ] || [ ! -s ".mcp.env" ]; then
    if [ -n "$BRAVE_API_KEY" ] && [ -n "$RESEND_API_KEY" ]; then
        print_step "Creating MCP secrets..."
        make gateway-secrets 2>/dev/null || {
            echo "mongodb.connection_string=mongodb://admin:password@mongodb:27017/" > .mcp.env
            echo "resend.api_key=${RESEND_API_KEY}" >> .mcp.env
            echo "brave.api_key=${BRAVE_API_KEY}" >> .mcp.env
        }
        print_success "Created MCP secrets file"
    else
        print_warning "BRAVE_API_KEY and/or RESEND_API_KEY not found"
        echo "Please set these environment variables:"
        echo "  export BRAVE_API_KEY=your-brave-key"
        echo "  export RESEND_API_KEY=your-resend-key"
        echo "Then run: make gateway-secrets"
        echo
    fi
fi

print_step "Choosing optimal configuration..."

# Check available memory (rough estimate)
available_memory=$(docker system info 2>/dev/null | grep "Total Memory" | awk '{print $3}' || echo "0")
memory_gb=$(echo "$available_memory" | sed 's/GiB//' | sed 's/MB//' | cut -d'.' -f1)

echo "Detected system memory: ${available_memory}"

# Determine best configuration
if [ -f "secret.openai-api-key" ] && [ -s "secret.openai-api-key" ]; then
    print_success "Using OpenAI API configuration (recommended)"
    compose_files="compose.yaml"
    config_description="OpenAI GPT-4o-mini (no local VRAM needed)"
elif [ "$memory_gb" -gt 8 ]; then
    print_warning "Using small local model configuration"
    compose_files="compose.yaml -f compose.local-model.yaml"
    config_description="Phi3-mini local model (~2GB VRAM needed)"
else
    print_error "Insufficient resources for local model and no OpenAI API key found"
    echo "Please either:"
    echo "1. Set up OpenAI API key: echo 'sk-your-key' > secret.openai-api-key"
    echo "2. Use a system with more memory/VRAM"
    exit 1
fi

print_step "Starting services with: $config_description"
echo "Command: docker compose $compose_files up --build -d"
echo

# Start services
if docker compose $compose_files up --build -d; then
    print_success "Services started successfully!"
else
    print_error "Failed to start services. Check the logs:"
    echo "docker compose logs"
    exit 1
fi

print_step "Waiting for services to initialize..."
sleep 15

# Check service health
print_step "Checking service health..."
unhealthy=$(docker compose ps --format "table {{.Service}}\t{{.Status}}" | grep -v "Up" | grep -v "SERVICE" || true)

if [ -z "$unhealthy" ]; then
    print_success "All services are running!"
else
    print_warning "Some services may need more time to start:"
    echo "$unhealthy"
    echo
    echo "This is often normal - give them a few more minutes"
fi

print_step "Verifying interceptor setup..."

# Check if interceptors are mounted
if docker compose exec mcp-gateway ls /interceptors/ >/dev/null 2>&1; then
    interceptor_count=$(docker compose exec mcp-gateway ls /interceptors/*.sh 2>/dev/null | wc -l)
    print_success "Interceptors mounted successfully ($interceptor_count scripts found)"
else
    print_warning "Interceptor mount may have issues"
fi

# Check if log directory exists
if docker compose exec mcp-gateway ls /var/log/ >/dev/null 2>&1; then
    print_success "Log directory is accessible"
else
    print_warning "Log directory mount may have issues"
fi

echo
echo "🌐 Access Points"
echo "================"
echo "🛡️  Interceptor Dashboard: http://localhost:8090"
echo "🛒 Sock Store: http://localhost:9090"  
echo "🤖 Agent Portal: http://localhost:3000"

echo
echo "🧪 Next Steps"
echo "============="
echo "1. Run the demo script:"
echo "   ./demo-interceptors.sh"
echo
echo "2. Test the Agent Portal:"
echo "   Visit http://localhost:3000"
echo "   Submit: 'Nike compression socks for \$12.99'"
echo
echo "3. Monitor interceptor logs:"
echo "   docker compose exec mcp-gateway tail -f /var/log/mcp-interceptors.log"

echo
print_success "Quick fix completed! The interceptor demo should now be working."

echo
echo "💡 Troubleshooting Tips"
echo "======================"
echo "- If services are still starting: wait 2-3 minutes and check 'docker compose ps'"
echo "- If Agent Portal errors: restart with 'docker compose restart adk adk-ui'"
echo "- If interceptor logs are empty: try submitting a request via the Agent Portal"
echo "- For detailed troubleshooting: see TROUBLESHOOTING.md"
