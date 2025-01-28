#!/bin/bash

handle_zsh_config_error() {
    echo "--| stage 3 |-----------------------------------------------------------------------"
    echo "Error: Zsh configuration failed."
    echo "Possible issues:"
    echo "  - .zshrc file not found."
    echo "  - Syntax errors in .zshrc."
    echo "What to do:"
    echo "  - Manually configure Zsh by editing ~/.zshrc."
    echo "------------------------------------------------------------------------------------"
}

handle_zsh_plugin_error() {
    echo "--| stage 3 |-----------------------------------------------------------------------"
    echo "Error: Zsh plugin installation failed."
    echo "Possible issues:"
    echo "  - Network issues during download."
    echo "  - Missing dependencies (git)."
    echo "What to do:"
    echo "  - Manually install the plugin: git clone <plugin-repo> ~/.zsh/plugins/<plugin-name>"
    echo "------------------------------------------------------------------------------------"
}
