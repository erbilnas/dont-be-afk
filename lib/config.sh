#!/bin/bash

# Configuration Management Module
# Handles loading and saving configuration

# Configuration file path
CONFIG_FILE="$HOME/.dont-be-afk-config"

# Default values
DEFAULT_X=500
DEFAULT_Y=300
DEFAULT_INTERVAL=600

# Function to load configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
        if [[ -n "$x_coord" && -n "$y_coord" && -n "$interval" ]]; then
            return 0
        fi
    fi
    return 1
}

# Function to save configuration
save_config() {
    cat > "$CONFIG_FILE" <<EOF
x_coord=$x_coord
y_coord=$y_coord
interval=$interval
log_to_file=$log_to_file
EOF
}
