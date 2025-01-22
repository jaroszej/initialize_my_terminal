#!/bin/bash

# Exit on errors
set -e

# Function to source helper and error handler files
source_files() {
    local script_dir="$(dirname "$0")"

    # Source helper.sh
    local helper_file="$script_dir/helper.sh"
    if [ -f "$helper_file" ]; then
        source "$helper_file"
    else
        echo "Error: Helper file not found at $helper_file"
        exit 1
    fi

    # Source all error handler files
    for stage in 1 2 3; do
        local error_handlers_file="$script_dir/stage_${stage}_error_handlers.sh"
        if [ -f "$error_handlers_file" ]; then
            source "$error_handlers_file"
        else
            echo "Error: Error handlers file not found at $error_handlers_file"
            exit 1
        fi
    done
}

# Source all necessary files
source_files

# Function to run a stage and handle errors
run_stage() {
    local stage_script=$1
    local stage_number=$2

    echo "🚀 Starting Stage $stage_number..."
    if ! ./"$stage_script"; then
        echo ""
        echo "❌ Error: Stage $stage_number failed."
        echo "--------------------------------------------------"
        echo "Check the logs above for specific errors."
        echo "Refer to the error handler in $stage_script for resolution steps."
        echo "--------------------------------------------------"
        echo "Exiting script. Please resolve the issue and re-run."
        exit 1
    fi
}

# Run stage_1.sh
run_stage "stage_1.sh" 1

# Run stage_2.sh
run_stage "stage_2.sh" 2

# Run stage_3.sh
run_stage "stage_3.sh" 3

echo ""
echo "✅ All stages completed successfully! Your environment is now set up."
echo "You may need to restart your terminal or run 'source ~/.zshrc' to apply changes."