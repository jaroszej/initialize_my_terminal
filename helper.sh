#!/bin/bash

temp_dir="/tmp/initialize_my_terminal"
after_install="./after_install"
mkdir -p "$temp_dir" "$after_install"
scroll_temp_file="$temp_dir/scroll_avail.temp"
nvm_installed_temp_file="$temp_dir/nvm_installed.temp"
zsh_setup_temp_file="$temp_dir/zsh_setup.temp"
export OPTIONAL_PKG_LOG="$after_install/optional_packages_failed.log"
export zsh_config="$HOME/.zshrc"
export bash_config="$HOME/.bashrc"

check_shell() {
    ps -p $$ -o comm=
}

refresh_shell() {
    CURRENT_SHELL=$(check_shell)
    case "$CURRENT_SHELL" in
        bash)
            echo "Running in Bash, reloading ~/.bashrc"
            # shellcheck disable=SC1090
            source "$bash_config"
            ;;
        zsh)
            echo "Running in Zsh, reloading ~/.zshrc"
            # shellcheck disable=SC1090
            source "$zsh_config"
            ;;
        *)
            echo "Unknown shell: $CURRENT_SHELL"
            ;;
    esac
}

try_catch() {
    local try_command="$1"
    local catch_command="$2"

    if output=$(eval "$try_command" 2>&1); then
        echo "Success: $try_command"
    else
        local exit_code=$?
        echo "!! Error: $try_command failed with exit code $exit_code"
        echo "Output: $output"
        eval "$catch_command"
        return $exit_code
    fi
}

retry_command() {
    local cmd="$1"
    local error_handler="$2"
    local stagename="${3:-}"
    local attempt="${4:-1}"

    if try_catch "$cmd" "$error_handler"; then
        return 0
    fi

    if [ "$RETRY" = true ] && [ "$attempt" -eq 1 ]; then
        if [ -n "$stagename" ]; then
            wrapper_frame "$stagename" "!! Warning: Command failed, retrying once..."
        else
            echo "!! Warning: Command failed, retrying once..."
        fi
        sleep 2
        if retry_command "$cmd" "$error_handler" "$stagename" 2; then
            return 0
        fi
    fi

    if [ -n "$stagename" ]; then
        wrapper_frame "$stagename" "!! Error: Command failed after retry."
    else
        echo "!! Error: Command failed after retry."
    fi
    return 1
}

source_files() {
    local script_dir="$(dirname "$0")"
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

update_and_upgrade() {
    echo "Updating and upgrading system packages..."
    sudo apt update && sudo apt upgrade -y
}

install_necessary_package() {
    local package="$1"
    local yes=$2

    echo "Installing necessary package: $package..."
    if sudo apt install -y "$package"; then
        echo "Successfully installed $package"
    else
        echo "!! Error: Failed to install $package"
        exit 1
    fi
}

install_optional_package() {
    local package="$1"
    local yes=$2

    echo "Installing optional package: $package..."
    if sudo apt install -y "$package"; then
        echo "Successfully installed $package"
    else
        echo "!! Warning: Failed to install $package"
        
        # Check if package is already logged
        if ! grep -qx "$package" "$OPTIONAL_PKG_LOG" 2>/dev/null; then
            echo "$package" >> "$OPTIONAL_PKG_LOG"
            echo "Logged $package as failed in $OPTIONAL_PKG_LOG"
        fi
    fi
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
                echo "Press 'S' to start ${installed[0]}"
                echo "Enter 'C' to continue without starting a ${installed[0]} session"
                echo "Enter 'Q' to quit and close the script"
                read -r response
                case "$response" in
                    [Cc]) echo "Continuing..."; return ;;
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
                echo "Press 'Enter' to continue without starting a ${installed[0]} or ${installed[1]} session"
                echo "Enter 'T' to start ${installed[0]}"
                echo "Enter 'S' to start ${installed[1]}"
                echo "Enter 'Q' to quit and close the script"
                read -r choice
                choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]')
                case "$choice" in
                    t) make_scroll_temp_file; enter_scroll "${installed[0]}"; return ;;
                    s) make_scroll_temp_file; enter_scroll "${installed[1]}"; return ;;
                    q) echo "Exiting initialize_my_terminal..."; exit 0 ;;
                    "") echo "Continuing..."; return ;;
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

check_stage_temp_file() {
    local stage_number=$1
    local stage_temp_file="$temp_dir/stage_${stage_number}.temp"

    [ -f "$stage_temp_file" ]
}

check_scroll_temp_file() {
    [ -f "$scroll_temp_file" ]
}

check_nvm_installed_temp_file() {
    [ -f "$nvm_installed_temp_file" ]
}

check_zsh_setup_temp_file() {
    [ -f "$zsh_setup_temp_file" ]
}

make_scroll_temp_file() {
    if check_scroll_temp_file; then
        echo "Scroll temp file already exists."
    else
        touch "$scroll_temp_file"
        echo "Scroll session recorded in $scroll_temp_file."
    fi
}

make_nvm_installed_temp_file() {
    if check_nvm_installed_temp_file; then
        echo "NVM temp file already exists."
    else
        touch "$nvm_installed_temp_file"
        echo "NVM session recorded in $nvm_installed_temp_file."
    fi
}

make_stage_temp_file() {
    local stage_number=$1
    local stage_temp_file="$temp_dir/stage_${stage_number}.temp"

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
        local stage_temp_file="$temp_dir/stage_${stage}.temp"
        if [ -f "$stage_temp_file" ]; then
            rm "$stage_temp_file"
            echo "Removed stage $stage temp file."
        fi
    done
}

clear_nvm_installed_temp_file() {
    if check_nvm_installed_temp_file; then
        rm "$nvm_installed_temp_file"
        echo ""
        echo "NVM session flag removed from $nvm_installed_temp_file."
    fi
}

clear_zsh_setup_temp_file() {
    if check_zsh_setup_temp_file; then
        rm "$zsh_setup_temp_file"
        echo ""
        echo "Zsh setup session flag removed from $zsh_setup_temp_file."
    fi
}

wrapper_frame() {
    echo "==| $1 |========================================================================="
    echo "$2"
    echo "===================================================================================="
}

add_env_var() {
    local var_name="$1"
    local var_value="$2"
    local to_add="export $var_name=\"$var_value\""
    local check="^export $var_name="

    if ! grep "$check" ~/.zshenv; then
        echo "$to_add" >> ~/.zshenv
    fi

    if ! grep "$check" ~/.zshenv; then
        echo "!! Error: Failed to add $var_name to ~/.zshenv."
        exit 1     
    fi

    echo "Added $var_name to ~/.zshenv"
}
