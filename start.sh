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

    echo "==| start |========================================================================="
    echo "--> Starting Stage $stage_number..."
    echo "===================================================================================="
    if ! ./"$stage_script"; then
        echo ""
        echo "--| start.sh |----------------------------------------------------------------------"
        echo "!! Error: Stage $stage_number failed."
        echo "------------------------------------------------------------------------------------"
        echo "Check the logs above for specific errors."
        echo ""
        echo "If your terminal does not natively support scroll, you can install 'tmux' or 'screen' using apt"
        echo "  How to scroll using tmux or screen:"
        echo "    # Enter Copy mode:"
        echo "      - tmux: '^B' then  '['"
        echo "      - screen: '^A' then '['"
        echo "    # tmux Scroll:"
        echo "      - Up/Down Arrow or Pg Up/Pg Down to scroll up or down"
        echo "      - ^U and ^D to scroll a half page up or down"
        echo "      - 'gg' to go to the top of the buffer"
        echo "      - 'G' to go to the bottom of the buffer"
        echo "    # screen Scroll:"
        echo "      - Up/Down Arrow or Pg Up/Pg Down to scroll up or down"
        echo "      - ^U and ^D to scroll a half page up or down"
        echo ""
        echo "Refer to the error handler in $stage_script for resolution steps."
        echo "------------------------------------------------------------------------------------"
        echo "Exiting initialize_my_terminal. Please resolve the issue and re-run."
        exit 1
    fi
}

echo "==| start |========================================================================="
echo " Stage: 0/3"
echo "===================================================================================="
run_stage "stage_1.sh" 1

echo "==| start |========================================================================="
echo " Stage: 1/3"
echo "===================================================================================="
run_stage "stage_2.sh" 2

echo "==| start |========================================================================="
echo " Stage: 2/3"
echo "===================================================================================="
run_stage "stage_3.sh" 3

echo ""
echo "==| start |========================================================================="
echo " Stage: 3/3"
echo "===================================================================================="
echo ""
echo "OK: All stages completed successfully! Your environment is now set up."
echo "NOTE: You may need to restart your terminal or run 'source ~/.zshrc' to apply changes."
echo "===================================================================================="
echo ""
