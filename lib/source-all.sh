#!/bin/bash

# Source all library modules
# This file sources all modules in the correct order

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR"

# Source all modules in dependency order
source "$LIB_DIR/config.sh"
source "$LIB_DIR/logger.sh"
source "$LIB_DIR/utils.sh"
source "$LIB_DIR/validation.sh"
source "$LIB_DIR/process.sh"
source "$LIB_DIR/install.sh"
source "$LIB_DIR/input.sh"
source "$LIB_DIR/click.sh"
