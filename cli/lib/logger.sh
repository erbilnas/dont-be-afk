#!/bin/bash

# Logger Module
# Handles logging functionality

# Use Application Support directory to avoid permission prompts on macOS
APP_SUPPORT_DIR="$HOME/Library/Application Support/DontBeAFK"

# Create directory if it doesn't exist
mkdir -p "$APP_SUPPORT_DIR" 2>/dev/null

LOG_FILE="$APP_SUPPORT_DIR/log"

# Function to log message
log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_entry="[$timestamp] $message"
    
    echo "$log_entry"
    
    if [[ "$log_to_file" == true ]]; then
        echo "$log_entry" >> "$LOG_FILE"
    fi
}
