#!/bin/bash

# Sock Store Business Logic Interceptor
# This interceptor enforces specific business rules for the sock store vendor system
# Usage: before:exec:/interceptors/sock_store_business.sh

# Function to validate vendor submissions
validate_vendor_submission() {
    local input="$1"
    
    # Check if this is a vendor-related call
    if echo "$input" | grep -qi "vendor\|supplier\|nike\|adidas\|sock"; then
        echo "[$(date)] SOCK_STORE: Processing vendor-related request" >> /var/log/mcp-interceptors.log
        
        # Business Rule 1: Minimum price validation
        if echo "$input" | grep -oP '\$([0-9]+\.[0-9]{2})' | head -1 | grep -oP '[0-9]+\.[0-9]{2}' | awk '$1 < 5.00'; then
            echo "[$(date)] SOCK_STORE: ❌ REJECTED: Price below minimum threshold (\$5.00)" >> /var/log/mcp-interceptors.log
            echo "ERROR: Product price must be at least \$5.00 to maintain quality standards." >&2
            exit 1
        fi
        
        # Business Rule 2: Competitor brand detection
        local blocked_brands=("cheap_socks_inc" "knockoff_brand" "counterfeit_co")
        for brand in "${blocked_brands[@]}"; do
            if echo "$input" | grep -qi "$brand"; then
                echo "[$(date)] SOCK_STORE: ❌ REJECTED: Blocked brand detected: $brand" >> /var/log/mcp-interceptors.log
                echo "ERROR: This brand is not approved for our marketplace." >&2
                exit 1
            fi
        done
        
        # Business Rule 3: Required product information
        local required_fields=("price" "material" "size")
        for field in "${required_fields[@]}"; do
            if ! echo "$input" | grep -qi "$field"; then
                echo "[$(date)] SOCK_STORE: ⚠️  WARNING: Missing required field: $field" >> /var/log/mcp-interceptors.log
            fi
        done
        
        # Business Rule 4: Image URL validation
        if echo "$input" | grep -o "https\?://[^[:space:]]*\.(jpg\|jpeg\|png\|gif)" | head -1; then
            image_url=$(echo "$input" | grep -o "https\?://[^[:space:]]*\.(jpg\|jpeg\|png\|gif)" | head -1)
            echo "[$(date)] SOCK_STORE: ✅ Valid image URL detected: $image_url" >> /var/log/mcp-interceptors.log
        else
            echo "[$(date)] SOCK_STORE: ⚠️  WARNING: No valid image URL found" >> /var/log/mcp-interceptors.log
        fi
        
        # Business Rule 5: Automatic categorization
        if echo "$input" | grep -qi "compression"; then
            echo "[$(date)] SOCK_STORE: 🏷️  Auto-categorized as: Athletic/Compression" >> /var/log/mcp-interceptors.log
        elif echo "$input" | grep -qi "dress\|formal\|business"; then
            echo "[$(date)] SOCK_STORE: 🏷️  Auto-categorized as: Formal/Business" >> /var/log/mcp-interceptors.log
        elif echo "$input" | grep -qi "casual\|everyday"; then
            echo "[$(date)] SOCK_STORE: 🏷️  Auto-categorized as: Casual/Everyday" >> /var/log/mcp-interceptors.log
        fi
    fi
}

# Function to enrich vendor data
enrich_vendor_data() {
    local input="$1"
    
    # Add automatic fields
    current_date=$(date -Iseconds)
    vendor_id="VENDOR_$(date +%s)"
    
    # Add metadata if this is a vendor submission
    if echo "$input" | grep -qi "vendor\|supplier"; then
        # Add timestamp and vendor ID to the submission
        enriched_input=$(echo "$input" | jq --arg date "$current_date" --arg vid "$vendor_id" \
            '. + {submission_timestamp: $date, vendor_id: $vid, status: "pending_review"}' 2>/dev/null || echo "$input")
        echo "$enriched_input"
    else
        echo "$input"
    fi
}

# Main processing
echo "[$(date)] SOCK_STORE: Business logic interceptor activated" >> /var/log/mcp-interceptors.log

# Read the input
input=$(cat)

# Validate vendor submissions
validate_vendor_submission "$input"

# Enrich the data
enriched_input=$(enrich_vendor_data "$input")

echo "[$(date)] SOCK_STORE: ✅ Business validation passed, forwarding request" >> /var/log/mcp-interceptors.log

# Pass through the enriched input
echo "$enriched_input"
