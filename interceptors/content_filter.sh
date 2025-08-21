#!/bin/bash

# Content Filter Interceptor
# This interceptor filters content based on business rules and compliance requirements
# Usage: after:exec:/interceptors/content_filter.sh

# Function to filter inappropriate content
filter_content() {
    local input="$1"
    
    # Business rule: Filter out competitor mentions
    local competitors=("adidas" "puma" "under armour" "new balance" "reebok")
    for competitor in "${competitors[@]}"; do
        if echo "$input" | grep -qi "$competitor"; then
            input=$(echo "$input" | sed -i "s/$competitor/[COMPETITOR_NAME]/gi")
        fi
    done
    
    # Filter sensitive information patterns
    # Remove potential email addresses from responses
    input=$(echo "$input" | sed -E 's/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/[EMAIL_REDACTED]/g')
    
    # Remove potential phone numbers
    input=$(echo "$input" | sed -E 's/\b[0-9]{3}-[0-9]{3}-[0-9]{4}\b/[PHONE_REDACTED]/g')
    
    # Filter profanity (simplified list)
    local profanity_words=("damn" "hell" "crap" "stupid" "idiotic")
    for word in "${profanity_words[@]}"; do
        input=$(echo "$input" | sed -i "s/\\b$word\\b/[FILTERED]/gi")
    done
    
    echo "$input"
}

# Function to apply sock store business rules
apply_business_rules() {
    local input="$1"
    
    # Ensure brand consistency - replace generic terms with brand-specific ones
    input=$(echo "$input" | sed 's/\bsocks\b/premium socks/g')
    input=$(echo "$input" | sed 's/\bfootwear\b/premium footwear/g')
    
    # Add disclaimers for price mentions
    if echo "$input" | grep -qi "price\|cost\|\$"; then
        input="$input\n\n*Prices subject to change. Please check our website for current pricing."
    fi
    
    # Add quality assurance messaging
    if echo "$input" | grep -qi "quality\|material\|fabric"; then
        input="$input\n\n*All our products meet the highest quality standards and come with our satisfaction guarantee."
    fi
    
    echo "$input"
}

# Log the intercepted response
echo "[$(date)] CONTENT_FILTER: Processing tool response" >> /var/log/mcp-interceptors.log

# Read the tool response
input=$(cat)

# Check if this is a tool response (contains result data)
if echo "$input" | grep -q '"result"'; then
    echo "[$(date)] CONTENT_FILTER: Applying content filters and business rules" >> /var/log/mcp-interceptors.log
    
    # Apply content filtering
    filtered_input=$(filter_content "$input")
    
    # Apply business rules
    final_output=$(apply_business_rules "$filtered_input")
    
    # Log any changes made
    if [[ "$input" != "$final_output" ]]; then
        echo "[$(date)] CONTENT_FILTER: ✅ Content modified for compliance and branding" >> /var/log/mcp-interceptors.log
    fi
    
    echo "$final_output"
else
    # Pass through non-result content unchanged
    echo "$input"
fi
