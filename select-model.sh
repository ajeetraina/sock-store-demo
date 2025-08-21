#!/bin/bash

# Model Selection Script for Docker MCP Gateway Demo
# Automatically chooses the best model based on your system capabilities

set -e

echo "🤖 Docker MCP Gateway - Lightweight Model Selector"
echo "=================================================="
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
        # NVIDIA GPU detected
        vram=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -1)
        echo $((vram))
    elif command -v rocm-smi >/dev/null 2>&1; then
        # AMD GPU detected
        vram=$(rocm-smi --showmeminfo vram | grep "vram Total Memory" | awk '{print $4}' | head -1)
        echo $((vram / 1024 / 1024))  # Convert to MB
    elif [ "$(uname)" = "Darwin" ]; then
        # macOS - estimate based on total memory (unified memory)
        total_mem=$(sysctl -n hw.memsize)
        # Assume 1/4 of total memory available for GPU tasks
        echo $(( total_mem / 1024 / 1024 / 4 ))
    else
        # Unknown - assume minimal
        echo "0"
    fi
}

# Function to detect total system memory
detect_memory() {
    if [ "$(uname)" = "Darwin" ]; then
        # macOS
        sysctl -n hw.memsize | awk '{print int($1/1024/1024/1024)}'
    elif [ "$(uname)" = "Linux" ]; then
        # Linux
        grep MemTotal /proc/meminfo | awk '{print int($2/1024/1024)}'
    else
        echo "8"  # Default assumption
    fi
}

print_step "Detecting system capabilities..."

vram_mb=$(detect_vram)
total_mem_gb=$(detect_memory)

echo "💾 Detected VRAM: ${vram_mb}MB"
echo "🧠 Detected RAM: ${total_mem_gb}GB"
echo

# Recommend configuration based on capabilities
print_step "Analyzing optimal configuration..."

if [ -f "secret.openai-api-key" ] && [ -s "secret.openai-api-key" ]; then
    print_success "OpenAI API key found - RECOMMENDED OPTION"
    echo "🌟 Best choice: Use OpenAI API (no local resources needed)"
    echo "   Command: docker compose up --build -d"
    echo
    recommended="openai"
elif [ "$vram_mb" -ge 8000 ]; then
    print_success "High VRAM available - Multiple options"
    echo "🚀 You can use larger models like Mistral 7B or Llama 3.2 3B"
    echo "   Command: docker compose -f compose.yaml -f compose.local-model.yaml up -d"
    recommended="large_local"
elif [ "$vram_mb" -ge 2000 ]; then
    print_success "Moderate VRAM available"
    echo "⚡ Recommended: Phi3-mini (2GB VRAM needed)"
    echo "   Command: docker compose -f compose.yaml -f compose.local-model.yaml up -d"
    recommended="medium_local"
elif [ "$vram_mb" -ge 700 ] || [ "$total_mem_gb" -ge 4 ]; then
    print_warning "Limited VRAM but should work"
    echo "🔬 Recommended: TinyLlama (700MB VRAM needed)"
    echo "   Command: docker compose -f compose.yaml -f compose.tinyllama.yaml up -d"
    recommended="tiny_local"
else
    print_error "Very limited resources detected"
    echo "💡 Recommendation: Use OpenAI API or upgrade hardware"
    echo "   Get OpenAI key: https://platform.openai.com/api-keys"
    echo "   Then: echo 'sk-your-key' > secret.openai-api-key"
    recommended="upgrade_needed"
fi

echo
echo "📋 All Available Options:"
echo "========================"
echo
echo "1️⃣  OpenAI API (Recommended - No local resources needed)"
echo "   💰 Cost: ~\$0.50-2.00 per session"
echo "   ⚡ Performance: Excellent"
echo "   🔧 Setup: echo 'sk-your-key' > secret.openai-api-key"
echo "   🚀 Start: docker compose up --build -d"
echo

echo "2️⃣  Phi3-mini (2GB VRAM needed)"
echo "   💾 Download: 2.3GB"
echo "   ⚡ Performance: Good"
echo "   🔧 Requirements: 2GB+ VRAM"
echo "   🚀 Start: docker compose -f compose.yaml -f compose.local-model.yaml up -d"
echo

echo "3️⃣  TinyLlama (700MB VRAM needed)"
echo "   💾 Download: 700MB"
echo "   ⚡ Performance: Basic but functional"
echo "   🔧 Requirements: 700MB+ VRAM or works on CPU"
echo "   🚀 Start: docker compose -f compose.yaml -f compose.tinyllama.yaml up -d"
echo

echo "4️⃣  Custom Selection (Edit compose.lightweight-models.yaml)"
echo "   💾 Various options from 700MB to 4GB"
echo "   ⚡ Performance: Varies"
echo "   🔧 Setup: Uncomment desired model in compose.lightweight-models.yaml"
echo "   🚀 Start: docker compose -f compose.yaml -f compose.lightweight-models.yaml up -d"

echo
print_step "Quick Actions:"

case $recommended in
    "openai")
        echo "🌟 RECOMMENDED: Set up OpenAI API key for best experience"
        if [ -z "$OPENAI_API_KEY" ]; then
            echo "   export OPENAI_API_KEY=sk-your-key-here"
            echo "   echo \$OPENAI_API_KEY > secret.openai-api-key"
        fi
        ;;
    "large_local"|"medium_local")
        echo "⚡ RECOMMENDED: Use Phi3-mini local model"
        echo "   docker compose -f compose.yaml -f compose.local-model.yaml up --build -d"
        ;;
    "tiny_local")
        echo "🔬 RECOMMENDED: Use TinyLlama ultra-lightweight model"
        echo "   docker compose -f compose.yaml -f compose.tinyllama.yaml up --build -d"
        ;;
    "upgrade_needed")
        echo "💡 RECOMMENDED: Get OpenAI API key or upgrade hardware"
        echo "   OpenAI keys: https://platform.openai.com/api-keys"
        ;;
esac

echo
echo "🚀 After starting, run the demo:"
echo "   ./demo-interceptors.sh"
echo
echo "📊 Access points:"
echo "   🛡️  Interceptor Dashboard: http://localhost:8090"
echo "   🤖 Agent Portal: http://localhost:3000"
echo "   🛒 Sock Store: http://localhost:9090"

echo
print_step "Model comparison by resource usage:"
echo

cat << 'EOF'
| Model          | VRAM    | Download | Performance | Best For           |
|----------------|---------|----------|-------------|--------------------|
| OpenAI API     | 0MB     | 0MB      | Excellent   | Production use     |
| Mistral 7B     | 4GB     | 4.1GB    | Very Good   | High-end systems   |
| Llama 3.2 3B   | 2GB     | 2.0GB    | Good        | Balanced choice    |
| Phi3-mini      | 2GB     | 2.3GB    | Good        | Most laptops       |
| Gemma 2B       | 1.5GB   | 1.6GB    | Fair        | Mid-range systems  |
| TinyLlama      | 700MB   | 700MB    | Basic       | Minimal systems    |
EOF

echo
print_success "Model selection complete! Choose your preferred option above."
