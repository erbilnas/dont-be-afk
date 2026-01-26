#!/bin/bash

# Click Module
# Handles click execution and main loop

# Function to perform click with error handling
perform_click() {
    # Get current position before attempting move
    local before_pos=$(cliclick p 2>/dev/null)
    
    # Use m: to move cursor visibly to the location, then c: to click
    # Combining both in one command ensures the cursor moves before clicking
    if ! cliclick m:$x_coord,$y_coord c:$x_coord,$y_coord 2>/dev/null; then
        log_message "❌ ERROR: Failed to click at ($x_coord, $y_coord)"
        log_message "   Check accessibility permissions in System Preferences"
        return 1
    fi
    
    # Verify the cursor actually moved (cliclick returns 0 even without permissions)
    local after_pos=$(cliclick p 2>/dev/null)
    if [[ "$before_pos" == "$after_pos" ]]; then
        # Cursor didn't move - likely a permissions issue
        log_message "⚠️  WARNING: Cursor did not move. Check Accessibility permissions!"
        log_message "   Go to: System Settings → Privacy & Security → Accessibility"
        log_message "   Ensure 'Don't Be AFK' (or Terminal/cliclick) is enabled"
        return 1
    fi
    
    return 0
}

# Function to run the main loop
run_loop() {
    local click_count=0
    
    log_message "🚀 Starting automation"
    log_message "📍 Coordinates: ($x_coord, $y_coord)"
    log_message "⏰ Interval: $interval seconds"
    
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
