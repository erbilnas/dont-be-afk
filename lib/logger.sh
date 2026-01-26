#!/bin/bash

# Logger Module
# Handles logging functionality

LOG_FILE="$HOME/.dont-be-afk.log"

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
