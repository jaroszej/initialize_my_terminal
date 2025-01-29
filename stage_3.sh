#!/bin/bash

set -e

stagename="stage 3"

# Parse command-line arguments
while [ $# -gt 0 ]; do
    case "$1" in
        -r|--retry)
            RETRY=true
            shift
            ;;
        *)
            ;;
        # -y|--yes)
        #     YES=true
        #     shift
        #     ;;
    esac
done

retry_wrapper() {
    local cmd="$1"
    local error_handler="$2"
    local stagename="${3:-}"

    if [ "$RETRY" = true ]; then
        retry_command "$cmd" "$error_handler" "$stagename"
    else
        if eval "$cmd"; then
            return 0
        else
            eval "$error_handler"
            return 1
        fi
    fi
}

if source_helper; then
    if source_files; then
        # Main logic
        echo "Checking if Zsh is installed..."
        if command -v zsh >/dev/null 2>&1; then
            echo "Zsh found: $(zsh --version)"
        else
            echo "!! Error: Zsh is not installed. Please install Zsh before running this script."
            exit 1
        fi

        echo "Checking if Zsh is the default shell..."
        if [ "$(readlink /proc/$$/exe)" = "/bin/zsh" ]; then
            echo "Zsh is the default shell."
        else
            echo "!! Error: Zsh is not the default shell. Please set Zsh as the default shell and re-run this script."
            exit 1
        fi

        echo "Installing Znap..."
        ZNAP_DIR="$HOME/Znap_Repos/znap"
        if [ ! -d "$ZNAP_DIR" ]; then
            retry_wrapper "git clone --depth 1 https://github.com/marlonrichert/zsh-snap.git \"$ZNAP_DIR\"" \
                          "echo '!! Error: Failed to install Znap.'"
            echo "Znap installed successfully."
        else
            echo "Znap is already installed."
        fi

        echo "Installing zsh-autocomplete..."
        ZSH_AUTOCOMPLETE_DIR="$HOME/Repos/zsh-autocomplete"
        if [ ! -d "$ZSH_AUTOCOMPLETE_DIR" ]; then
            retry_wrapper "git clone --depth 1 https://github.com/marlonrichert/zsh-autocomplete.git \"$ZSH_AUTOCOMPLETE_DIR\"" \
                          "echo '!! Error: Failed to install zsh-autocomplete.'"
            echo "zsh-autocomplete installed successfully."
        else
            echo "zsh-autocomplete is already installed."
        fi

        echo "Configuring ~/.zshrc for Znap, zsh-autocomplete, and custom user functions..."
        if ! grep -q "znap.zsh" ~/.zshrc; then
            cat << EOF >> ~/.zshrc

# Load Znap
[[ -r $ZNAP_DIR/znap.zsh ]] && source $ZNAP_DIR/znap.zsh

# Load zsh-autocomplete
source $ZSH_AUTOCOMPLETE_DIR/zsh-autocomplete.plugin.zsh

# Plugins
znap source zsh-users/zsh-completions
znap source zsh-users/zsh-syntax-highlighting
znap source sindresorhus/pure

# CLI Color Variables
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
WHITE='\033[0;37m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RESET='\033[0m' # Reset color

# Function to tag user-defined functions
fn_tag() {
    echo -e "\${BLUE}User Zsh Fn\${RESET} \${WHITE}=>\${RESET} \${GREEN}\$1\${RESET}"
}

# Function to edit the .zshrc file
edit_config() {
    fn_tag "edit_config"
    nano ~/.zshrc
}

EOF
            echo "Znap and zsh-autocomplete configuration added to ~/.zshrc."
        else
            echo "Znap configuration already exists in ~/.zshrc."
        fi

        echo "Adding skip_global_compinit=1 to ~/.zshenv for zsh-autocomplete..."
        if ! grep -q "skip_global_compinit=1" ~/.zshenv; then
            echo "skip_global_compinit=1" >> ~/.zshenv
            echo "skip_global_compinit=1 added to ~/.zshenv."
        else
            echo "skip_global_compinit=1 already exists in ~/.zshenv."
        fi

        echo ""
        echo "Stage 3 setup is complete. Setup complete. You may need to restart your terminal for some changes to take effect."
        echo ""
        echo "**Reminder** Set up gpg-agent and pass"
        echo "> gpg --full-gen-key"
        echo "and"
        echo "pass init <gpg-key-id>"
        echo "pass git init"
        echo "If you are on WSL you may need to reassign the Wayland-0 socket path"

        exit 0

    else
        wrapper_frame "$stagename" "!! Error: Failed to source needed files."
        exit 1
    fi
else
    wrapper_frame "$stagename" "!! Error: Failed to source helper file."
    exit 1
fi
