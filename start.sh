#!/bin/bash

set -e

source_files() {
    local script_dir="$(dirname "$0")"

    local helper_file="$script_dir/helper.sh"
    if [ -f "$helper_file" ]; then
        source "$helper_file"
    else
        start_wrapper "!! Error: Helper file not found at $helper_file"
        exit 1
    fi

    # Source all error handler files
    for stage in 1 2 3; do
        local error_handlers_file="$script_dir/stage_${stage}_error_handlers.sh"
        if [ -f "$error_handlers_file" ]; then
            source "$error_handlers_file"
        else
            start_wrapper "!! Error: Error handlers file not found at $error_handlers_file"
            exit 1
        fi
    done
}

run_stage() {
    local stage_script="stage_$1.sh"
    local stage_number=$1

    if [ ! -f "$stage_script" ]; then
        start_wrapper "!! Error: Stage $stage_number script ($stage_script) not found."
        exit 1
    elif [ ! -x "$stage_script" ]; then
        start_wrapper "!! Error: Stage $stage_number script ($stage_script) is not executable."
        exit 1
    fi

    start_wrapper "--> Starting Stage $stage_number..."

    if ! source "$stage_script"; then
        echo ""
        start_wrapper "!! Error: Stage $stage_number failed."
        echo "Check the logs above for specific errors."
        echo ""
        echo "Refer to the error handler in $stage_script for resolution steps."
        echo "===================================================================================="
        echo "Exiting initialize_my_terminal. Please resolve the issue and re-run."
        exit 1
    fi
}

# Source all necessary files
source_files

warn_enable_scroll

# Run stages
for i in {1..3}; do
    if check_stage_temp_file "$i"; then
        start_wrapper "INFO: Stage $i temp file detected. Skipping stage $i."
    else
        num=$(("$i" - 1))
        start_wrapper " Progress: Stage $num/3"

        if run_stage "$i"; then
            make_stage_temp_file "$i"
        else
            start_wrapper "!! Error: Unexpected failure. You may need to remove temp files in /tmp/initialize_my_terminal/ to restart from scratch."
            exit 1
        fi
    fi
done

clear_scroll_temp_file
clear_stage_temp_files

echo ""
start_wrapper " Stage 3/3"
echo ""
echo "OK: All stages completed successfully! Your environment is now set up."
echo "NOTE: You may need to restart your terminal or run 'source ~/.zshrc' to apply changes."
echo "===================================================================================="
echo ""
