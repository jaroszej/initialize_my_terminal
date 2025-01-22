#!/bin/bash

# Function to handle Zsh configuration errors
handle_zsh_config_error() {
    echo "Error: Zsh configuration failed."
    echo "Possible issues:"
    echo "  - .zshrc file not found."
    echo "  - Syntax errors in .zshrc."
    echo "What to do:"
    echo "  - Manually configure Zsh by editing ~/.zshrc."
}

# Function to handle Antigen installation errors
handle_antigen_error() {
    echo "Error: Antigen installation failed."
    echo "Possible issues:"
    echo "  - Network issues during download."
    echo "  - Missing dependencies (curl, git)."
    echo "What to do:"
    echo "  - Manually install Antigen: curl -L git.io/antigen > ~/.antigen.zsh"
}

# Function to handle Zsh plugin installation errors
handle_zsh_plugin_error() {
    echo "Error: Zsh plugin installation failed."
    echo "Possible issues:"
    echo "  - Network issues during download."
    echo "  - Missing dependencies (git)."
    echo "What to do:"
    echo "  - Manually install the plugin: git clone <plugin-repo> ~/.zsh/plugins/<plugin-name>"
}
