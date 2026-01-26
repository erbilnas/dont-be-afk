#!/bin/bash

# Validation Module
# Handles coordinate and screen validation

# Function to get screen resolution
get_screen_resolution() {
    if command -v system_profiler &> /dev/null; then
        # Get primary display resolution
        local resolution=$(system_profiler SPDisplaysDataType 2>/dev/null | grep -A 1 "Resolution:" | tail -1 | awk '{print $1, $3}' | tr ' ' 'x')
        if [[ -n "$resolution" ]]; then
            echo "$resolution"
        fi
    fi
}

# Function to validate coordinates are within screen bounds
validate_coordinates() {
    local x=$1
    local y=$2
    
    # Try to get screen resolution
    local resolution=$(get_screen_resolution)
    if [[ -n "$resolution" ]]; then
        local width=$(echo "$resolution" | cut -d'x' -f1)
        local height=$(echo "$resolution" | cut -d'x' -f2)
        
        if [[ -n "$width" && -n "$height" ]]; then
            if [[ $x -gt $width ]] || [[ $y -gt $height ]]; then
                echo "⚠️  Warning: Coordinates ($x, $y) may be outside screen bounds ($width x $height)"
                echo "   Continue anyway? (y/n)"
                read -r response
                if [[ ! "$response" =~ ^[Yy]$ ]]; then
                    return 1
                fi
            fi
        fi
    fi
    return 0
}

# Function to warn if interval exceeds Mac lock time
warn_if_interval_exceeds_lock_time() {
    local interval=$1
    local lock_time=$(get_mac_lock_time)
    
    # If lock time is 0, password is not required, so no warning needed
    if [[ "$lock_time" -eq 0 ]]; then
        return 0
    fi
    
    # If interval exceeds lock time, warn the user
    if [[ "$interval" -gt "$lock_time" ]]; then
        echo ""
        echo "⚠️  Warning: Your interval ($interval seconds) is longer than your Mac's lock time ($lock_time seconds)"
        echo "   Your Mac may lock before the next click, which could prevent the script from working."
        echo "   Consider setting a shorter interval or adjusting your Mac's lock settings."
        echo ""
    fi
}
