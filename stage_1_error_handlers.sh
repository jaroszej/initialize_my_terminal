#!/bin/bash

# Function to handle Zsh installation errors
handle_zsh_error() {
    echo "--| stage 1 |-----------------------------------------------------------------------"
    echo "Error: Zsh installation failed."
    echo "Possible issues:"
    echo "  - Network issues during package download."
    echo "  - Missing dependencies."
    echo "  - Permission issues (check sudo privileges)."
    echo "What to do:"
    echo "  - Manually install Zsh: sudo apt install zsh"
    echo "------------------------------------------------------------------------------------"
}
