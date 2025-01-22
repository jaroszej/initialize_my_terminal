#!/bin/bash

# Function to handle Docker installation errors
handle_docker_error() {
    echo "Error: Docker installation failed."
    echo "Possible issues:"
    echo "  - Network issues during package download."
    echo "  - Missing dependencies."
    echo "  - Permission issues (check sudo privileges)."
    echo "What to do:"
    echo "  - Manually install Docker: https://docs.docker.com/engine/install/ubuntu/"
}

# Function to handle Golang installation errors
handle_golang_error() {
    echo "Error: Golang installation failed."
    echo "Possible issues:"
    echo "  - Network issues during package download."
    echo "  - Missing dependencies."
    echo "What to do:"
    echo "  - Manually install Golang: https://golang.org/doc/install"
}

# Function to handle Java installation errors
handle_java_error() {
    echo "Error: Java installation failed."
    echo "Possible issues:"
    echo "  - Network issues during package download."
    echo "  - Missing dependencies."
    echo "What to do:"
    echo "  - Manually install Java: sudo apt install openjdk-17-jdk"
}

# Function to handle NVM installation errors
handle_nvm_error() {
    echo "Error: NVM installation failed."
    echo "Possible issues:"
    echo "  - Network issues during download."
    echo "  - Missing dependencies (curl, git)."
    echo "What to do:"
    echo "  - Manually install NVM: https://github.com/nvm-sh/nvm"
}

# Function to handle Node.js installation errors
handle_node_error() {
    echo "Error: Node.js installation failed."
    echo "Possible issues:"
    echo "  - NVM not properly installed."
    echo "  - Network issues during Node.js download."
    echo "What to do:"
    echo "  - Manually install Node.js: nvm install --lts"
}

# Function to handle pnpm installation errors
handle_pnpm_error() {
    echo "Error: pnpm installation failed."
    echo "Possible issues:"
    echo "  - npm not properly installed."
    echo "  - Network issues during pnpm download."
    echo "What to do:"
    echo "  - Manually install pnpm: npm install -g pnpm"
}

# Function to handle Rust installation errors
handle_rust_error() {
    echo "Error: Rust installation failed."
    echo "Possible issues:"
    echo "  - Network issues during Rust installation."
    echo "What to do:"
    echo "  - Manually install Rust: https://www.rust-lang.org/tools/install"
}

# Function to handle Homebrew installation errors
handle_homebrew_error() {
    echo "Error: Homebrew installation failed."
    echo "Possible issues:"
    echo "  - Network issues during installation."
    echo "  - Missing dependencies (curl, git)."
    echo "What to do:"
    echo "  - Manually install Homebrew: https://brew.sh/"
}
