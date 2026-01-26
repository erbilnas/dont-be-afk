#!/bin/bash

# Utilities Module
# Handles interval parsing and formatting

# Function to parse interval (only accepts seconds)
parse_interval() {
    local input=$1
    
    # Only accept numbers (seconds)
    if [[ "$input" =~ ^[0-9]+$ ]]; then
        echo "$input"
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

# Function to get Mac lock time (screen saver timeout + password delay)
get_mac_lock_time() {
    # Check if password is required after screen saver
    # This setting can be in the current user's domain or global domain
    local require_password=$(defaults read com.apple.screensaver askForPassword 2>/dev/null)
    
    # If password is not required, return 0 (no lock time)
    # Note: If the setting doesn't exist, defaults returns an error, so we check for "1" specifically
    if [[ "$require_password" != "1" ]]; then
        echo "0"
        return 0
    fi
    
    # Get screen saver idle time (in seconds)
    # This is the time until screen saver starts
    local idle_time=$(defaults read com.apple.screensaver idleTime 2>/dev/null)
    
    # Get password delay (in seconds)
    # This is the delay after screen saver starts before password is required
    local password_delay=$(defaults read com.apple.screensaver askForPasswordDelay 2>/dev/null)
    
    # Handle case where settings might not exist
    # If idle_time is not set, screen saver might be disabled, so return 0
    if [[ -z "$idle_time" ]]; then
        echo "0"
        return 0
    fi
    
    # Default password delay to 0 if not set
    password_delay=${password_delay:-0}
    
    # Total lock time = idle time + password delay
    local total_time=$((idle_time + password_delay))
    echo "$total_time"
}
