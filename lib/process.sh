#!/bin/bash

# Process Management Module
# Handles process lifecycle (start, stop, status)

# Use Application Support directory to avoid permission prompts on macOS
APP_SUPPORT_DIR="$HOME/Library/Application Support/DontBeAFK"

# Create directory if it doesn't exist
mkdir -p "$APP_SUPPORT_DIR" 2>/dev/null

PID_FILE="$APP_SUPPORT_DIR/pid"

# Function to check if another instance is running
check_running() {
    if [[ -f "$PID_FILE" ]]; then
        local pid=$(cat "$PID_FILE" 2>/dev/null)
        if ps -p "$pid" > /dev/null 2>&1; then
            echo "⚠️  Another instance is already running (PID: $pid)"
            echo "   Use './dont-be-afk stop' to stop it, or './dont-be-afk status' to check status"
            exit 1
        else
            # Stale PID file
            rm -f "$PID_FILE"
        fi
    fi
}

# Function to stop running instance
stop_instance() {
    if [[ ! -f "$PID_FILE" ]]; then
        echo "❌ No running instance found"
        exit 1
    fi
    
    local pid=$(cat "$PID_FILE" 2>/dev/null)
    if ps -p "$pid" > /dev/null 2>&1; then
        kill "$pid" 2>/dev/null
        rm -f "$PID_FILE"
        echo "✅ Stopped instance (PID: $pid)"
    else
        rm -f "$PID_FILE"
        echo "❌ Process not found (stale PID file removed)"
    fi
    exit 0
}

# Function to check status
check_status() {
    if [[ ! -f "$PID_FILE" ]]; then
        echo "❌ No running instance"
        exit 0
    fi
    
    local pid=$(cat "$PID_FILE" 2>/dev/null)
    if ps -p "$pid" > /dev/null 2>&1; then
        echo "✅ Instance is running (PID: $pid)"
        if [[ -f "$CONFIG_FILE" ]]; then
            source "$CONFIG_FILE"
            echo "   Coordinates: ($x_coord, $y_coord)"
            echo "   Interval: $interval seconds"
        fi
    else
        rm -f "$PID_FILE"
        echo "❌ No running instance (stale PID file removed)"
    fi
    exit 0
}
