#!/bin/bash

# Utilities Module
# Handles interval parsing and formatting

# Function to parse human-readable interval (e.g., "5m", "10m", "1h")
parse_interval() {
    local input=$1
    
    # If it's just a number, assume seconds
    if [[ "$input" =~ ^[0-9]+$ ]]; then
        echo "$input"
        return 0
    fi
    
    # Parse formats like "5m", "10m", "1h", "30s"
    if [[ "$input" =~ ^([0-9]+)([smhd])$ ]]; then
        local value="${BASH_REMATCH[1]}"
        local unit="${BASH_REMATCH[2]}"
        
        case "$unit" in
            s) echo "$value" ;;
            m) echo "$((value * 60))" ;;
            h) echo "$((value * 3600))" ;;
            d) echo "$((value * 86400))" ;;
            *) return 1 ;;
        esac
        return 0
    fi
    
    return 1
}

# Function to format interval for display
format_interval() {
    local seconds=$1
    local hours=$((seconds / 3600))
    local minutes=$(((seconds % 3600) / 60))
    local secs=$((seconds % 60))
    
    local result=""
    if [[ $hours -gt 0 ]]; then
        result="${hours}h "
    fi
    if [[ $minutes -gt 0 ]]; then
        result="${result}${minutes}m "
    fi
    if [[ $secs -gt 0 ]] || [[ -z "$result" ]]; then
        result="${result}${secs}s"
    fi
    echo "$result"
}
