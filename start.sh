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
        echo "      - tmux: enter 'Ctrl + B' followed by  '['"
        echo "      - screen: enter 'Ctrl+A' followed by 'Esc'"
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

check_installed() {
    local installed=()
    if which tmux >/dev/null 2>&1; then
        installed+=("tmux")
    fi
    if which screen >/dev/null 2>&1; then
        installed+=("screen")
    fi
    echo "${installed[@]}"
}

warn_enable_scroll() {
    while true; do
        mapfile -t installed < <(check_installed)

        if [ ${#installed[@]} -eq 0 ]; then
            echo ""
            echo "Warning: Some environments may not natively support scrolling, making troubleshooting very difficult. Before proceeding, please ensure your terminal supports scrolling."
            echo ""
            echo "If your terminal does not natively support scroll, you can install 'tmux', 'screen', or another tool using apt to scroll through old outputs."
            echo ""
            while true; do
                echo "Press 'Enter' to continue without using tmux or screen to scroll"
                echo "Press 'Q' to quit and close the script..."
                read -r response
                if [[ "$response" =~ ^[Qq]$ ]]; then
                    echo "Exiting initialize_my_terminal..."
                    exit 0
                fi

                break # continue to stages
            done
        elif [ ${#installed[@]} -eq 1 ]; then
            while true; do
                echo "Found ${installed[0]} installed."
                echo ""
                echo "Press 'Enter' to start ${installed[0]}"
                echo "Enter 'C' to continue without ${installed[0]}"
                echo "Enter 'Q' to quit and close the script"
                read -r response
                if [[ "$response" =~ ^[Cc]$ ]]; then
                    echo "Continuing without ${installed[0]}."
                elif [[ "$response" =~ ^[Qq]$ ]]; then
                    echo "Exiting initialize_my_terminal..."
                    exit 0
                else
                    enter_scroll "${installed[0]}"
                fi

                break # continue to stages
            done
        else
            while true; do
                echo "Found ${installed[0]} and ${installed[1]} installed."
                echo "Enter 'T' to start ${installed[0]}"
                echo "Enter 'S' to start ${installed[1]}"
                echo "Enter 'Q' to quit and close the script"
                read -r choice
                choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]')
                if [[ "$choice" == ^[Tt] ]]; then
                    enter_scroll "tmux"
                    break
                elif [[ "$choice" == ^[Ss] ]]; then
                    enter_scroll "screen"
                    break
                elif [[ "$choice" == "q" ]]; then
                    echo "Exiting script. Goodbye!"
                    exit 0
                else
                    echo "!! Error: Invalid input. Please enter 'T', 'S', or 'Q'."
                fi
            done
        fi
    done
}

enter_scroll() {
    case "$1" in
        "tmux")
            echo ""
            echo "You are entering tmux."
            echo "To scroll in tmux, enter 'Ctrl + B' followed by '[':"
            echo "  - Up/Down Arrow or Pg Up/Pg Down to scroll up or down"
            echo "  - ^U and ^D to scroll a half page up or down"
            echo "  - 'gg' to go to the top of the buffer"
            echo "  - 'G' to go to the bottom of the buffer"
            echo "  - 'q' to exit"
            echo ""
            echo "Press Enter to continue and open tmux."
            read -r
            tmux
            ;;
        "screen")
            echo ""
            echo "You are entering screen."
            echo "To scroll in screen, enter 'Ctrl+A' followed by 'Esc':"
            echo "  - Up/Down Arrow or Pg Up/Pg Down to scroll up or down"
            echo "  - ^U and ^D to scroll a half page up or down"
            echo "  - Press 'Esc' again to exit copy mode."
            echo ""
            echo "Press Enter to continue and open screen."
            read -r
            screen
            ;;
        *)
            echo "$1 is an invalid option."
            exit 1
            ;;
    esac
}

warn_enable_scroll

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
