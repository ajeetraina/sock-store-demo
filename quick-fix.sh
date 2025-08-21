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

# Function to detect available VRAM
detect_vram() {
    if command -v nvidia-smi >/dev/null 2>&1; then
        vram=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -1)
        echo $((vram))
    elif [ "$(uname)" = "Darwin" ]; then
        # macOS - estimate based on total memory (unified memory)
        total_mem=$(sysctl -n hw.memsize)
        echo $(( total_mem / 1024 / 1024 / 4 ))
    else
        echo "2000"  # Conservative estimate
    fi
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

print_step "Making scripts executable..."
chmod +x interceptors/*.sh 2>/dev/null || true
chmod +x demo-interceptors.sh 2>/dev/null || true
chmod +x select-model.sh 2>/dev/null || true

print_step "Checking for required API keys..."

# Check if OpenAI API key exists
if [ ! -f "secret.openai-api-key" ] || [ ! -s "secret.openai-api-key" ]; then
    if [ -n "$OPENAI_API_KEY" ]; then
        echo "$OPENAI_API_KEY" > secret.openai-api-key
        print_success "Created OpenAI API key file from environment variable"
    else
        print_warning "OpenAI API key not found. Will use local model."
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

print_step "Selecting optimal model configuration..."

# Detect system capabilities
vram_mb=$(detect_vram)
echo "💾 Detected VRAM: ${vram_mb}MB"

# Choose best configuration
if [ -f "secret.openai-api-key" ] && [ -s "secret.openai-api-key" ]; then
    print_success "Using OpenAI API configuration (recommended)"
    compose_files="compose.yaml"
    config_description="OpenAI GPT-4o-mini (no local VRAM needed)"
elif [ "$vram_mb" -ge 2000 ]; then
    print_success "Using Phi3-mini local model"
    compose_files="compose.yaml -f compose.local-model.yaml"
    config_description="Phi3-mini local model (~2GB VRAM needed)"
elif [ "$vram_mb" -ge 700 ]; then
    print_warning "Using TinyLlama ultra-lightweight model"
    compose_files="compose.yaml -f compose.tinyllama.yaml"
    config_description="TinyLlama local model (~700MB VRAM needed)"
else
    print_error "Insufficient resources detected. Trying TinyLlama anyway..."
    compose_files="compose.yaml -f compose.tinyllama.yaml"
    config_description="TinyLlama local model (minimal resources)"
fi

print_step "Starting services with: $config_description"
echo "Command: docker compose $compose_files up --build -d"
echo

# Start services
if docker compose $compose_files up --build -d; then
    print_success "Services started successfully!"
else
    print_error "Failed to start services. Trying with minimal configuration..."
    print_step "Attempting fallback to OpenAI API configuration..."
    
    # Create a minimal OpenAI key if none exists
    if [ ! -f "secret.openai-api-key" ]; then
        echo "# Add your OpenAI API key here" > secret.openai-api-key
        print_warning "Created placeholder OpenAI key file. Add your key: echo 'sk-your-key' > secret.openai-api-key"
    fi
    
    # Try with basic configuration
    if docker compose up --build -d; then
        print_success "Fallback configuration started!"
    else
        print_error "Still failing. Check the logs:"
        echo "docker compose logs"
        exit 1
    fi
fi

print_step "Waiting for services to initialize..."
sleep 20

# Check service health
print_step "Checking service health..."
unhealthy=$(docker compose ps --format "table {{.Service}}\t{{.Status}}" | grep -v "Up" | grep -v "SERVICE" || true)

if [ -z "$unhealthy" ]; then
    print_success "All services are running!"
else
    print_warning "Some services may need more time to start:"
    echo "$unhealthy"
    echo
    echo "Common issues and solutions:"
    
    # Check for model issues
    if docker compose logs adk 2>/dev/null | grep -q "model too big"; then
        echo "🔧 Model too big: Try a smaller model"
        echo "   ./select-model.sh  # See all lightweight options"
        echo "   # Or use TinyLlama: docker compose -f compose.yaml -f compose.tinyllama.yaml up -d"
    fi
    
    # Check for API key issues
    if docker compose logs adk 2>/dev/null | grep -q "401\|Unauthorized\|API key"; then
        echo "🔑 API key issue: Set your OpenAI key"
        echo "   echo 'sk-your-key-here' > secret.openai-api-key"
        echo "   docker compose restart adk"
    fi
    
    echo
    echo "Give services a few more minutes to fully initialize..."
fi

print_step "Verifying interceptor setup..."

# Check if interceptors are mounted
if docker compose exec mcp-gateway ls /interceptors/ >/dev/null 2>&1; then
    interceptor_count=$(docker compose exec mcp-gateway ls /interceptors/*.sh 2>/dev/null | wc -l)
    print_success "Interceptors mounted successfully ($interceptor_count scripts found)"
else
    print_warning "Interceptor mount may have issues"
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
echo "3. Try different models:"
echo "   ./select-model.sh  # Interactive model selection"

echo
echo "💡 If you still have issues:"
echo "============================"
echo "1. Check service logs: docker compose logs adk"
echo "2. Try TinyLlama: docker compose -f compose.yaml -f compose.tinyllama.yaml up -d"
echo "3. Use OpenAI API: echo 'sk-your-key' > secret.openai-api-key && docker compose up -d"
echo "4. See TROUBLESHOOTING.md for detailed help"

echo
print_success "Quick fix completed! Your interceptor demo should be working with an appropriate model for your system."
