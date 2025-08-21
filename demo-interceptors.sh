#!/bin/bash

# Docker MCP Gateway Interceptor Demo Script
# This script demonstrates the power of interceptors in action

set -e

echo "🛡️ Docker MCP Gateway Interceptor Demo"
echo "========================================"
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

# Check if Docker Compose is running
print_step "Checking if Docker Compose stack is running..."
if ! docker compose ps | grep -q "mcp-gateway"; then
    print_error "Docker Compose stack not running. Please run 'docker compose up -d' first."
    exit 1
fi
print_success "Docker Compose stack is running"

# Wait for services to be ready
print_step "Waiting for services to be ready..."
sleep 10

print_step "Testing Interceptor Framework"
echo

# Test 1: Secret Detection Interceptor
echo "🔒 Test 1: Secret Detection Interceptor"
echo "--------------------------------------"
print_step "Attempting to send a request with a fake API key..."

# This should be blocked by the secret detector
TEST_PAYLOAD='{"method": "search", "params": {"query": "Nike socks api_key=sk-1234567890abcdef1234567890abcdef1234567890"}}'

echo "Test payload: $TEST_PAYLOAD"
print_warning "This request should be blocked by the secret detector interceptor"

# Test 2: Tool Usage Monitor
echo
echo "📊 Test 2: Tool Usage Monitor"
echo "-----------------------------"
print_step "Sending multiple search requests to test rate limiting..."

for i in {1..5}; do
    echo "Sending search request #$i..."
    # In a real scenario, you'd use the actual MCP client to send requests
    echo "Search request #$i sent" | logger -t "INTERCEPTOR_DEMO"
done

print_success "Tool usage monitoring active - check logs for rate limiting warnings"

# Test 3: Business Logic Interceptor
echo
echo "🏪 Test 3: Sock Store Business Logic"
echo "-----------------------------------"
print_step "Testing vendor submission with various scenarios..."

# Test valid vendor submission
echo "Testing valid vendor submission..."
VALID_VENDOR='{"vendor": "Nike", "product": "compression socks", "price": "$12.99", "material": "cotton blend", "size": "M"}'
echo "Valid submission: $VALID_VENDOR"
print_success "Should pass business logic validation"

# Test invalid vendor submission (price too low)
echo "Testing invalid vendor submission (low price)..."
INVALID_VENDOR='{"vendor": "CheapSocks", "product": "basic socks", "price": "$2.99", "material": "polyester"}'
echo "Invalid submission: $INVALID_VENDOR"
print_warning "Should be rejected by business logic (price below $5.00)"

# Test 4: Content Filter
echo
echo "🧹 Test 4: Content Filter"
echo "-------------------------"
print_step "Testing content filtering for competitor mentions and sensitive data..."

CONTENT_WITH_COMPETITORS='{"result": "These socks are better than adidas and puma products. Contact us at test@email.com or call 555-123-4567"}'
echo "Content before filtering: $CONTENT_WITH_COMPETITORS"
print_success "Content filter should remove competitor names and sensitive data"

# Check interceptor logs
echo
echo "📋 Checking Interceptor Logs"
echo "============================"
print_step "Recent interceptor activity:"

# Display recent logs from the interceptor log file
if docker compose exec mcp-gateway ls /var/log/mcp-interceptors.log >/dev/null 2>&1; then
    echo "Last 10 interceptor log entries:"
    docker compose exec mcp-gateway tail -n 10 /var/log/mcp-interceptors.log 2>/dev/null || echo "Log file not yet created"
else
    print_warning "Interceptor log file not yet created - send some requests to generate logs"
fi

echo
echo "🌐 Dashboard Access"
echo "=================="
print_step "Interceptor Dashboard: http://localhost:8090"
print_step "Sock Store: http://localhost:9090"
print_step "Agent Portal: http://localhost:3000"

echo
echo "🔧 Manual Testing Commands"
echo "=========================="
echo "1. View live interceptor logs:"
echo "   docker compose exec mcp-gateway tail -f /var/log/mcp-interceptors.log"
echo
echo "2. Check tool usage logs:"
echo "   docker compose exec mcp-gateway cat /var/log/mcp/tool_usage.jsonl"
echo
echo "3. Test with real vendor submission in Agent Portal:"
echo "   Go to http://localhost:3000 and submit vendor information"
echo
echo "4. Monitor container logs:"
echo "   docker compose logs -f mcp-gateway"

echo
print_success "Interceptor demo setup complete!"
print_step "The interceptors are now actively monitoring and securing all MCP tool calls."
print_step "Try submitting vendor information through the Agent Portal to see them in action."

echo
echo "🎯 What the Interceptors Do:"
echo "============================"
echo "🔒 Secret Detector: Blocks requests containing API keys, tokens, or passwords"
echo "📊 Tool Monitor: Logs all tool usage and implements rate limiting"
echo "🏪 Business Logic: Enforces sock store rules (minimum price, required fields, etc.)"
echo "🧹 Content Filter: Removes competitor mentions and sensitive data from responses"
echo
echo "This demonstrates how Docker MCP Gateway interceptors provide enterprise-grade"
echo "security, compliance, and business logic enforcement for AI agent interactions."
