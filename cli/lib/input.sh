#!/bin/bash

# Input Module
# Handles user input for coordinates and intervals

# Function to get user input for coordinates
get_coordinates() {
    local use_defaults=false
    
    # Try to load from config
    if load_config && [[ -n "$x_coord" && -n "$y_coord" ]]; then
        echo ""
        echo "📍 Found saved coordinates: ($x_coord, $y_coord)"
        read -p "Use saved coordinates? (Y/n): " response
        if [[ -z "$response" ]] || [[ "$response" =~ ^[Yy]$ ]]; then
            use_defaults=true
        fi
    fi
    
    if [[ "$use_defaults" == false ]]; then
        echo ""
        echo "📍 Set click coordinates"
        if [[ -n "$x_coord" && -n "$y_coord" ]]; then
            echo "Current saved: ($x_coord, $y_coord)"
        else
            echo "Current default: ($DEFAULT_X, $DEFAULT_Y)"
        fi
        echo ""
        
        while true; do
            read -p "Enter X coordinate (or press Enter for default): " input
            if [[ -z "$input" ]]; then
                x_coord=${x_coord:-$DEFAULT_X}
            elif [[ ! "$input" =~ ^[0-9]+$ ]] || [[ "$input" -lt 0 ]]; then
                echo "❌ Please enter a valid positive number for X coordinate"
                continue
            else
                x_coord=$input
            fi
            break
        done
        
        while true; do
            read -p "Enter Y coordinate (or press Enter for default): " input
            if [[ -z "$input" ]]; then
                y_coord=${y_coord:-$DEFAULT_Y}
            elif [[ ! "$input" =~ ^[0-9]+$ ]] || [[ "$input" -lt 0 ]]; then
                echo "❌ Please enter a valid positive number for Y coordinate"
                continue
            else
                y_coord=$input
            fi
            break
        done
        
        # Validate coordinates
        if ! validate_coordinates "$x_coord" "$y_coord"; then
            return 1
        fi
    fi
    
    echo "✅ Coordinates set to: ($x_coord, $y_coord)"
}

# Function to get user input for interval
get_interval() {
    local use_defaults=false
    
    # Try to load from config
    if load_config && [[ -n "$interval" ]]; then
        echo ""
        echo "⏰ Found saved interval: $interval seconds"
        read -p "Use saved interval? (Y/n): " response
        if [[ -z "$response" ]] || [[ "$response" =~ ^[Yy]$ ]]; then
            use_defaults=true
        fi
    fi
    
    if [[ "$use_defaults" == false ]]; then
        echo ""
        echo "⏰ Set click interval"
        echo ""
        echo "Enter interval in seconds (e.g., 300, 600, 1800)"
        echo ""
        if [[ -n "$interval" ]]; then
            echo "Current saved: $interval seconds"
        else
            echo "Current default: $DEFAULT_INTERVAL seconds"
        fi
        echo ""
        
        while true; do
            read -p "Enter interval in seconds (or press Enter for default): " input
            if [[ -z "$input" ]]; then
                interval=${interval:-$DEFAULT_INTERVAL}
            else
                local parsed=$(parse_interval "$input")
                if [[ $? -eq 0 ]] && [[ -n "$parsed" ]] && [[ "$parsed" -ge 1 ]]; then
                    interval=$parsed
                else
                    echo "❌ Invalid format. Please enter a number (seconds only, e.g., 300, 600)"
                    continue
                fi
            fi
            break
        done
    fi
    
    echo "✅ Interval set to: $interval seconds"
    
    # Warn if interval exceeds Mac lock time
    warn_if_interval_exceeds_lock_time "$interval"
}
