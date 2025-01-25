#!/bin/bash

set -e

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

echo "Installing Antigen..."
if [ ! -f "$HOME/.antigen.zsh" ]; then
    try_catch \
        "curl -L git.io/antigen > $HOME/.antigen.zsh" \
        handle_antigen_error
    echo "Antigen installed successfully."
else
    echo "Antigen is already installed."
fi

echo "Configuring Antigen in ~/.zshrc..."
if ! grep -q "antigen.zsh" ~/.zshrc; then
    cat << 'EOF' >> ~/.zshrc
# Load Antigen
source ~/.antigen.zsh

# Load zsh-completions
antigen bundle zsh-users/zsh-completions

# Apply Antigen changes
antigen apply
EOF
    echo "Antigen configuration added to ~/.zshrc."
else
    echo "Antigen configuration already exists in ~/.zshrc."
fi

echo "Installing zsh-syntax-highlighting using Antigen..."
if ! grep -q "zsh-syntax-highlighting" ~/.zshrc; then
    cat << 'EOF' >> ~/.zshrc
# Load zsh-syntax-highlighting
antigen bundle zsh-users/zsh-syntax-highlighting
EOF
    echo "zsh-syntax-highlighting added to ~/.zshrc."
else
    echo "zsh-syntax-highlighting already configured in ~/.zshrc."
fi

echo "Stage 3 setup is complete. Setup complete. You may need to restart your terminal for some changes to take effect."
