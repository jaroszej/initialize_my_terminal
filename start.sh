#!/bin/bash

set -e

source_files() {
    local script_dir="$(dirname "$0")"

    local helper_file="$script_dir/helper.sh"
    if [ -f "$helper_file" ]; then
        source "$helper_file"
    else
        echo "!! Error: Helper file not found at $helper_file"
        exit 1
    fi

    # Source all error handler files
    for stage in 1 2 3; do
        local error_handlers_file="$script_dir/stage_${stage}_error_handlers.sh"
        if [ -f "$error_handlers_file" ]; then
            source "$error_handlers_file"
        else
            echo "!! Error: Error handlers file not found at $error_handlers_file"
            exit 1
        fi
    done
}

# Source all necessary files
source_files

run_stage() {
    local stage_script=$1
    local stage_number=$2

    if [ ! -f "$stage_script" ]; then
        echo "!! Error: Stage $stage_number script ($stage_script) not found."
        exit 1
    elif [ ! -x "$stage_script" ]; then
        echo "!! Error: Stage $stage_number script ($stage_script) is not executable."
        exit 1
    fi

    echo "===================================================================================="
    echo "--> Starting Stage $stage_number..."
    echo "===================================================================================="
    if ! ./"$stage_script"; then
        echo ""
        echo "!! Error: Stage $stage_number failed."
        echo "--------------------------------------------------"
        echo "Check the logs above for specific errors."
        echo "Refer to the error handler in $stage_script for resolution steps."
        echo "--------------------------------------------------"
        echo "Exiting script. Please resolve the issue and re-run."
        exit 1
    fi
}

run_stage "stage_1.sh" 1
run_stage "stage_2.sh" 2
run_stage "stage_3.sh" 3

echo ""
echo "===================================================================================="
echo "OK: All stages completed successfully! Your environment is now set up."
echo "You may need to restart your terminal or run 'source ~/.zshrc' to apply changes."
echo "===================================================================================="
echo ""
