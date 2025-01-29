#!/bin/bash

handle_docker_error() {
    echo "--| stage 2 |-----------------------------------------------------------------------"
    echo "Error: Docker installation failed. Attempted to install $1"
    echo "Possible issues:"
    echo "  - Network issues during package download."
    echo "  - Missing dependencies."
    echo "  - Permission issues (check sudo privileges)."
    echo "What to do:"
    echo "  - Manually install Docker: https://docs.docker.com/engine/install/ubuntu/"
    echo "------------------------------------------------------------------------------------"
}

handle_golang_error() {
    echo "--| stage 2 |-----------------------------------------------------------------------"
    echo "Error: Golang installation failed."
    echo "Possible issues:"
    echo "  - Network issues during package download."
    echo "  - Missing dependencies."
    echo "What to do:"
    echo "  - Manually install Golang: https://golang.org/doc/install"
    echo "------------------------------------------------------------------------------------"
}

handle_java_error() {
    echo "--| stage 2 |-----------------------------------------------------------------------"
    echo "Error: Java installation failed."
    echo "Possible issues:"
    echo "  - Network issues during package download."
    echo "  - Missing dependencies."
    echo "What to do:"
    echo "  - Manually install Java: sudo apt install openjdk-17-jdk"
    echo "------------------------------------------------------------------------------------"
}

handle_nvm_error() {
    echo "--| stage 2 |-----------------------------------------------------------------------"
    echo "Error: NVM installation failed."
    echo "Possible issues:"
    echo "  - Network issues during download."
    echo "  - Missing dependencies (curl, git)."
    echo "What to do:"
    echo "  - Manually install NVM: https://github.com/nvm-sh/nvm"
    echo "------------------------------------------------------------------------------------"
}

handle_node_error() {
    echo "--| stage 2 |-----------------------------------------------------------------------"
    echo "Error: Node.js installation failed."
    echo "Possible issues:"
    echo "  - NVM not properly installed."
    echo "  - Network issues during Node.js download."
    echo "What to do:"
    echo "  - Manually install Node.js: nvm install --lts"
    echo "------------------------------------------------------------------------------------"
}

handle_pnpm_error() {
    echo "--| stage 2 |-----------------------------------------------------------------------"
    echo "Error: pnpm installation failed."
    echo "Possible issues:"
    echo "  - npm not properly installed."
    echo "  - Network issues during pnpm download."
    echo "What to do:"
    echo "  - Manually install pnpm: npm install -g pnpm"
    echo "------------------------------------------------------------------------------------"
}

handle_rust_error() {
    echo "--| stage 2 |-----------------------------------------------------------------------"
    echo "Error: Rust installation failed."
    echo "Possible issues:"
    echo "  - Network issues during Rust installation."
    echo "What to do:"
    echo "  - Manually install Rust: https://www.rust-lang.org/tools/install"
    echo "------------------------------------------------------------------------------------"
}

handle_homebrew_error() {
    echo "--| stage 2 |-----------------------------------------------------------------------"
    echo "Error: Homebrew installation failed."
    echo "Possible issues:"
    echo "  - Network issues during installation."
    echo "  - Missing dependencies (curl, git)."
    echo "What to do:"
    echo "  - Manually install Homebrew: https://brew.sh/"
    echo "------------------------------------------------------------------------------------"
}

handle_zsh_config_error() {
    echo "--| stage 2 |-----------------------------------------------------------------------"
    echo "Error: Zsh configuration failed."
    echo "Possible issues:"
    echo "  - Network issues during package download."
    echo "  - Missing dependencies."
    echo "What to do:"
    echo "  - Manually install Zsh: sudo apt install zsh"
    echo "------------------------------------------------------------------------------------"
}
