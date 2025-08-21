#!/bin/bash

# Tool Usage Monitor Interceptor
# This interceptor logs and monitors all tool usage for compliance and analytics
# Usage: before:exec:/interceptors/tool_monitor.sh

# Function to extract tool name from MCP call
extract_tool_name() {
    local input="$1"
    # Extract tool name from JSON structure (simplified)
    echo "$input" | grep -o '"method":"[^"]*"' | cut -d'"' -f4 | head -1
}

# Function to extract arguments from MCP call
extract_arguments() {
    local input="$1"
    # Extract params from JSON (simplified)
    echo "$input" | grep -o '"params":{[^}]*}' | head -1
}

# Create log directory if it doesn't exist
mkdir -p /var/log/mcp

# Read the tool call input
input=$(cat)

# Extract tool information
tool_name=$(extract_tool_name "$input")
arguments=$(extract_arguments "$input")
timestamp=$(date -Iseconds)
user_agent=${HTTP_USER_AGENT:-"unknown"}

# Log the tool usage
log_entry="{
  \"timestamp\": \"$timestamp\",
  \"tool_name\": \"$tool_name\",
  \"arguments\": \"$arguments\",
  \"user_agent\": \"$user_agent\",
  \"session_id\": \"${SESSION_ID:-unknown}\"
}"

echo "$log_entry" >> /var/log/mcp/tool_usage.jsonl

# Also log to standard log
echo "[$(date)] TOOL_MONITOR: Tool '$tool_name' called with args: $arguments" >> /var/log/mcp-interceptors.log

# Check for suspicious patterns
if [[ "$tool_name" =~ (delete|drop|remove|destroy) ]] && [[ "$arguments" =~ (database|table|collection) ]]; then
    echo "[$(date)] TOOL_MONITOR: ⚠️  SUSPICIOUS: Destructive database operation detected" >> /var/log/mcp-interceptors.log
    # In production, you might want to require additional approval
fi

# Rate limiting check (simplified)
recent_calls=$(tail -n 100 /var/log/mcp/tool_usage.jsonl | grep -c "\"tool_name\": \"$tool_name\"")
if [[ $recent_calls -gt 20 ]]; then
    echo "[$(date)] TOOL_MONITOR: ⚠️  RATE_LIMIT: Tool '$tool_name' called $recent_calls times recently" >> /var/log/mcp-interceptors.log
fi

# Pass through the input
echo "$input"
