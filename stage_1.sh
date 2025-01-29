#!/bin/bash

set -e

stagename="stage 1"

source_helper() {
    local script_dir="$(dirname "$0")"

    local helper_file="$script_dir/helper.sh"
    if [ -f "$helper_file" ]; then
        source "$helper_file"
    else
        wrapper_frame "$stagename" "!! Error: Helper file not found at $helper_file"
        exit 1
    fi

}

check_dependencies() {
    local dependencies=("curl" "git" "wget" "tmux")
    local missing_dependencies=()
    local failed_dependencies=()

    # Check if dependencies are installed
    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing_dependencies+=("$dep")
        fi
    done

    if [ ${#missing_dependencies[@]} -gt 0 ]; then
        echo "The following dependencies are missing: ${missing_dependencies[*]}"
        echo "Attempting to install missing dependencies..."

        for dep in "${missing_dependencies[@]}"; do
            try_catch \
                "sudo apt install -y $dep" \
                "echo 'Failed to install $dep.'; failed_dependencies+=(\"$dep\")"
        done

        # If any dependencies failed to install, exit with an error
        if [ ${#failed_dependencies[@]} -gt 0 ]; then
            echo "!! Error: The following dependencies could not be installed: ${failed_dependencies[*]}"
            echo "Please install them manually and re-run the script."
            exit 1
        fi
    else
        echo "All dependencies are already installed."
    fi

    echo "setting default git branch to main"
    git config --global init.defaultBranch main
}

install_zsh() {
    echo "Installing Zsh..."
    try_catch \
        "sudo apt install -y zsh" \
        handle_zsh_error
    echo "Zsh installed successfully: $(zsh --version)"
}

prompt_retry_or_exit() {
    while true; do
        read -r -p "Do you want to try installing Zsh again? (y/n): " choice
        case "$choice" in
            y|Y )
                return 0  # Indicate retry
                ;;
            n|N )
                echo "Exiting setup. Please install Zsh manually and re-run the script."
                exit 1
                ;;
            * )
                echo "!! Error: Invalid input. Please enter 'y' to try installing Zsh again or 'n' to exit."
                ;;
        esac
    done
}

while [ $# -gt 0 ]; do # parse command line args 
    case "$1" in
        -r|--retry)
            RETRY=true
            shift
            ;;
        -y|--yes)
            YES=true
            shift
            ;;
        *)
            ;;
    esac
done

if source_helper; then
    if source_files; then
        # main logic
        echo "Updating and upgrading system packages..."
        sudo apt update && sudo apt upgrade -y

        check_dependencies

        echo "Checking if Zsh is installed..."
        if command -v zsh >/dev/null 2>&1; then
            echo "Zsh is already installed: $(zsh --version)"
        else
            # Attempt to install Zsh
            while ! install_zsh; do
                prompt_retry_or_exit || continue
            done
        fi

        zsh_path="$(which zsh)"

        if [ -z "$zsh_path" ]; then
            if [ "$RETRY" = true ]; then
                echo "!! Error: Zsh path not found after installation. Please ensure Zsh is correctly installed and in your PATH."
                exit 1
            else
                echo "!! Error: Zsh path not found. Checking again in a new bash session..."
                exec bash stage_1.sh -r ${YES:+-y}
            fi
        fi

        # Prompt user to confirm the Zsh path
        if [ "$YES" != true ]; then
            while true; do
                echo "Zsh detected at: $zsh_path"
                read -r -p "Do you want to use this path? (y/n): " choice
                case "$choice" in
                    y|Y )
                        echo "Using Zsh path: $zsh_path"
                        break
                        ;;
                    n|N )
                        while true; do
                            read -r -p "Enter the correct path to Zsh: " user_path
                            if [ -x "$user_path" ]; then
                                zsh_path="$user_path"
                                echo "Updated Zsh path to: $zsh_path"
                                break
                            else
                                echo "!! Error: Invalid path or Zsh is not executable at the provided location. Please try again."
                            fi
                        done
                        break
                        ;;
                    * )
                        echo "!! Error: Invalid input. Please enter 'y' for yes or 'n' for no."
                        ;;
                esac
            done
        else
            echo "Using Zsh path: $zsh_path"
        fi

        if [[ "$zsh_path" != "$SHELL" ]]; then
            export SHELL="$zsh_path"
        fi

        current_shell=$(getent passwd "$USER" | cut -d: -f7)
        if [ "$current_shell" != "$zsh_path" ]; then
            echo "Setting Zsh as the default shell..."
            try_catch \
                "chsh -s $zsh_path" \
                "echo '!! Error: Failed to set Zsh as the default shell.\nSet it manually by running: \`chsh -s \'$zsh_path\'\` if the command \`echo $SHELL\` outputs \`/usr/bin/zsh\`'; exit 1"
            chsh -s "$zsh_path"
        else
            echo "Zsh is the default shell."
        fi

        # Automate Zsh initial configuration
        echo "Automating Zsh initial configuration..."
        if [ ! -f "$HOME/.zshrc" ]; then
            echo "2" | zsh || {
                echo "!! Error: Failed to configure Zsh. Please configure it manually by running Zsh."
                exit 1
            }
        fi

        # Switch to Zsh and execute the second script
        echo ""
        echo "Stage 1 setup is complete. Switching to Zsh and continuing setup in stage_2.sh..."

        exit 0
                
    else
        wrapper_frame "$stagename" "!! Error: Failed to source needed files."
        exit 1
    fi
else
    wrapper_frame "$stagename" "!! Error: Failed to source helper file."
    exit 1
fi

