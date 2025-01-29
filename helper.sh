#!/bin/bash

temp_dir="/tmp/initialize_my_terminal"
mkdir -p "$temp_dir"
scroll_temp_file="$temp_dir/scroll_avail.temp"
zsh_setup_temp_file="$temp_dir/zsh_setup.temp"

try_catch() {
    local try_command=$1
    local catch_command=$2

    if output=$($try_command 2>&1); then
        echo "Success: $try_command"
    else
        local exit_code=$?
        echo "!! Error: $try_command failed with exit code $exit_code"
        echo "Output: $output"
        $catch_command
        return $exit_code
    fi
}

try_catch_finally() {
    local try_command=$1
    local catch_command=$2
    local finally_command=$3

    if output=$($try_command 2>&1); then
        echo "Success: $try_command"
    else
        local exit_code=$?
        echo "!! Error: $try_command failed with exit code $exit_code"
        echo "Command output: $output"
        $catch_command
        return $exit_code
    fi

    $finally_command
}

check_for_scroll_tool() {
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
    if check_scroll_temp_file; then
        return
    fi

    while true; do
        read -r -a installed <<< "$(check_for_scroll_tool)"
        
        echo ""
        echo "Warning: Some environments may not natively support scrolling, making troubleshooting very difficult. Before proceeding, please ensure your terminal supports scrolling."
        echo ""

        if [ ${#installed[@]} -eq 0 ]; then
            echo "If your terminal does not natively support scroll, you can install 'tmux', 'screen', or another tool using apt to scroll through old outputs."
            echo ""
            echo "Press 'Enter' to continue without using tmux or screen to scroll"
            echo "Press 'Q' to quit and close the script..."
            read -r response
            case "$response" in
                [Qq]) echo "Exiting initialize_my_terminal..."; exit 0 ;;
                *) return ;; # continue to stages
            esac

        elif [ ${#installed[@]} -eq 1 ]; then
            while true; do
                echo "Found ${installed[0]} installed."
                echo ""
                echo "If you start ${installed[0]} you will need to execute './start.sh' again to restart the script."
                echo ""
                echo "Press 'Enter' to start ${installed[0]}"
                echo "Enter 'C' to continue without ${installed[0]}"
                echo "Enter 'Q' to quit and close the script"
                read -r response
                case "$response" in
                    [Cc]) echo "Continuing without ${installed[0]}."; return ;;
                    [Qq]) echo "Exiting initialize_my_terminal..."; exit 0 ;;
                    *) 
                        make_scroll_temp_file
                        enter_scroll "${installed[0]}"
                        return
                        ;;
                esac
            done
        else
            while true; do
                echo "Found ${installed[0]} and ${installed[1]} installed."
                echo ""
                echo "If you start ${installed[0]} or ${installed[1]} you will need to execute './start.sh' again to restart the script."
                echo ""
                echo "Press 'Enter' to continue without starting ${installed[0]} or ${installed[1]}"
                echo "Enter 'T' to start ${installed[0]}"
                echo "Enter 'S' to start ${installed[1]}"
                echo "Enter 'Q' to quit and close the script"
                read -r choice
                choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]')
                case "$choice" in
                    t) make_scroll_temp_file; enter_scroll "${installed[0]}"; return ;;
                    s) make_scroll_temp_file; enter_scroll "${installed[1]}"; return ;;
                    q) echo "Exiting initialize_my_terminal..."; exit 0 ;;
                    "") echo "Continuing without using tmux or screen."; return ;;
                    *) echo "Invalid input. Please enter 'T', 'S', or 'Q' or press Enter to continue." ;;
                esac
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

make_scroll_temp_file() {
    if check_scroll_temp_file; then
        echo "Scroll temp file already exists."
    else
        touch "$scroll_temp_file"
        echo "Scroll session recorded in $scroll_temp_file."
    fi
}

make_stage_temp_file() {
    local stage_number=$1
    local stage_temp_file="$scroll_temp_dir/stage_${stage_number}.temp"

    if [ ! -f "$stage_temp_file" ]; then
        touch "$stage_temp_file"
        echo "Stage $stage_number session recorded in $stage_temp_file."
    else
        echo "Stage $stage_number temp file already exists."
    fi
}

make_zsh_setup_temp_file() {
    if check_zsh_setup_temp_file; then
        echo "Zsh setup temp file already exists."
    else
        touch "$zsh_setup_temp_file"
        echo "Zsh setup session recorded in $zsh_setup_temp_file."
    fi
}


clear_scroll_temp_file() {
    if check_scroll_temp_file; then
        rm "$scroll_temp_file"
        echo ""
        echo "Scroll session flag removed from $scroll_temp_file."
    fi
}

clear_stage_temp_files() {
    for stage in {1..3}; do
        local stage_temp_file="$scroll_temp_dir/stage_${stage}.temp"
        if [ -f "$stage_temp_file" ]; then
            rm "$stage_temp_file"
            echo "Removed stage $stage temp file."
        fi
    done
}

clear_zsh_setup_temp_file() {
    if check_zsh_setup_temp_file; then
        rm "$zsh_setup_temp_file"
        echo ""
        echo "Zsh setup session flag removed from $zsh_setup_temp_file."
    fi
}


check_stage_temp_file() {
    local stage_number=$1
    local stage_temp_file="$scroll_temp_dir/stage_${stage_number}.temp"

    [ -f "$stage_temp_file" ]
}

check_scroll_temp_file() {
    [ -f "$scroll_temp_file" ]
}

check_zsh_setup_temp_file() {
    [ -f "$zsh_setup_temp_file" ]
}

start_wrapper() {
    echo "==| start |========================================================================="
    echo "$1"
    echo "===================================================================================="
}
