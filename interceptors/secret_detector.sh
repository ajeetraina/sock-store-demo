#!/bin/bash

# Secret Detection Interceptor
# This interceptor scans tool calls for potential secret leakage
# Usage: before:exec:/interceptors/secret_detector.sh

# Function to detect potential secrets in text
detect_secrets() {
    local input="$1"
    
    # Check for various secret patterns
    if echo "$input" | grep -qiE "(password|api[_-]?key|secret|token|credential)" && \
       echo "$input" | grep -qE "[a-zA-Z0-9]{20,}"; then
        return 0  # Secret detected
    fi
    
    # Check for specific patterns
    if echo "$input" | grep -qE "(sk-[a-zA-Z0-9]{48}|ghp_[a-zA-Z0-9]{36}|xoxb-[a-zA-Z0-9-]+)"; then
        return 0  # OpenAI, GitHub, or Slack token detected
    fi
    
    return 1  # No secrets detected
}

# Log the intercepted call
echo "[$(date)] SECRET_DETECTOR: Scanning tool call for secrets" >> /var/log/mcp-interceptors.log

# Read the tool call input
input=$(cat)

# Detect secrets
if detect_secrets "$input"; then
    echo "[$(date)] SECRET_DETECTOR: ⚠️  POTENTIAL SECRET DETECTED - BLOCKING CALL" >> /var/log/mcp-interceptors.log
    echo "ERROR: Potential secret detected in tool call. Request blocked for security." >&2
    exit 1
fi

echo "[$(date)] SECRET_DETECTOR: ✅ No secrets detected - allowing call" >> /var/log/mcp-interceptors.log

# Pass through the input if no secrets detected
echo "$input"
