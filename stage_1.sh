#!/bin/bash

# Exit on errors
set -e

# collect user args
while [ $# -gt 0 ]; do
    case "$1" in
        -r|--retry)
            RETRY=true
            shift
            ;;
        -y|--yes)
            YES=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  -h, --help    Show this help message"
            echo "  -r, --retry   Retry installation if failed"
            echo "  -y, --yes    Skip confirmation prompts"
            exit 0
            ;;
        *)
            echo "!! Error: Unknown option: $1"
            echo "Use -h or --help for usage."
            exit 1
            ;;
    esac
done

check_dependencies() {
    local dependencies=("curl" "git" "wget")
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

## main logic

# Update and upgrade the system
echo "Updating and upgrading system packages..."
sudo apt update && sudo apt upgrade -y

check_dependencies

# Check if Zsh is already installed
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

export SHELL="$zsh_path"

echo "Setting Zsh as the default shell..."
chsh -s "$zsh_path"

## start stage_2.sh here, zsh doesn't automatically start

# Automate Zsh initial configuration
echo "Automating Zsh initial configuration..."
if [ ! -f "$HOME/.zshrc" ]; then
    echo "2" | zsh || {
        echo "!! Error: Failed to configure Zsh. Please configure it manually by running Zsh."
        exit 1
    }
fi

# Switch to Zsh and execute the second script
echo "Stage 1 setup is complete. Switching to Zsh and continuing setup in stage_2.sh..."

exec zsh stage_2.sh # will this require me to log in again?
