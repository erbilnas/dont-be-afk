#!/bin/bash

# Click Module
# Handles click execution and main loop

# Function to perform click with error handling
perform_click() {
    if ! cliclick m:$x_coord,$y_coord 2>/dev/null; then
        log_message "❌ ERROR: Failed to click at ($x_coord, $y_coord)"
        log_message "   Check accessibility permissions in System Preferences"
        return 1
    fi
    return 0
}

# Function to run the main loop
run_loop() {
    local click_count=0
    
    log_message "🚀 Starting automation"
    log_message "📍 Coordinates: ($x_coord, $y_coord)"
    log_message "⏰ Interval: $(format_interval $interval) ($interval seconds)"
    
    if [[ "$background_mode" == false ]]; then
        echo ""
        echo "Press Ctrl+C to stop"
        echo ""
    fi
    
    while true; do
        click_count=$((click_count + 1))
        
        if perform_click; then
            log_message "✅ Click #$click_count at ($x_coord, $y_coord)"
        else
            log_message "⚠️  Click #$click_count failed, will retry next interval"
        fi
        
        sleep "$interval"
    done
}
