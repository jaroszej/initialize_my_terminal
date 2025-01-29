#!/bin/bash

set -e

stagename="stage 2"

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


install_docker() {
    echo "Installing Docker and Docker Compose..."
    retry_wrapper "sudo apt update && sudo apt install -y docker.io docker-compose" "handle_docker_error"
    sudo systemctl start docker
    sudo systemctl enable docker
    echo "Docker installed successfully: $(docker --version)"
    echo ""
}

install_golang() {
    echo "Installing Golang..."
    retry_wrapper "sudo apt update && sudo apt install -y golang" "handle_golang_error"
    echo "Golang installed successfully: $(go version)"
    echo ""
}

install_java() {
    echo "Installing Java..."
    retry_wrapper "sudo apt update && sudo apt install -y openjdk-17-jdk" "handle_java_error"
    echo "Java installed successfully: $(java -version)"
    echo ""
}

# Install NVM, Node.js, and pnpm
install_nvm_node() {
    echo "Installing NVM..."
    if [ ! -d "$HOME/.nvm" ]; then
        retry_wrapper "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash" "handle_nvm_error"
    else
        echo "NVM is already installed."
    fi

    export NVM_DIR="$HOME/.nvm"
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        # shellcheck disable=SC1091
        . "$NVM_DIR/nvm.sh"
    else
        echo "!! Error: NVM script not found. Please verify your NVM installation."
        exit 1
    fi

    echo "Installing the latest LTS version of Node.js..."
    if retry_wrapper "nvm install --lts" "handle_node_error"; then
        echo "Node.js LTS installed successfully: $(node -v)"
    else
        echo "!! Error: Failed to install Node.js LTS."
        exit 1
    fi

    echo "Installing pnpm..."
    if retry_wrapper "npm install -g pnpm" "handle_pnpm_error"; then
        echo "pnpm installed successfully: $(pnpm -v)"
    else
        echo "!! Error: Failed to install pnpm."
        exit 1
    fi
    echo ""
}

install_rust() {
    echo "Installing Rust..."    
    retry_wrapper "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y" "handle_rust_error"

    RUST_ENV_FILE="$HOME/.cargo/env"
    if [ -f "$RUST_ENV_FILE" ]; then
        # shellcheck disable=SC1091
        source "$RUST_ENV_FILE"
        echo "Rust installed successfully: $(rustc --version)"
    else
        echo "NOTE: Rust installed, but $RUST_ENV_FILE not found."
        echo "Try restarting your shell or manually running: source ~/.cargo/env"
    fi

    echo ""
}

install_homebrew() {
    if command -v brew >/dev/null 2>&1; then
        echo "Homebrew is already installed: $(brew --version)"
        return 0
    fi

    echo "Installing required dependencies for Homebrew..."
    sudo apt-get update
    sudo apt-get install -y build-essential procps curl file git || {
        echo "!! Error: Failed to install dependencies for Homebrew."
        exit 1
    }

    echo "Installing Homebrew..."
    retry_wrapper "NONINTERACTIVE=1 /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"" \
        "echo '!! Error: Homebrew installation failed.'"

    echo "Configuring Homebrew environment..."
    {
        echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
    } | tee -a "$bash_config" "$zsh_config" > /dev/null

    refresh_shell

    try_catch "eval \"\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)\"" \
        "echo '!! Error: Failed to initialize Homebrew shell environment.'"
}

while [ $# -gt 0 ]; do # parse command line args 
    case "$1" in
        -r|--retry)
            RETRY=true
            shift
            ;;
        -y|--yes)
            YES='true'
            shift
            ;;
        *)
            ;;
    esac
done

if source_helper; then
    if source_files; then
        # main logic
        # Verify .zshrc exists
        if [ ! -f "$HOME/.zshrc" ]; then
            echo "!! Error: .zshrc file was not created. Please run Zsh manually to complete configuration."
            exit 1
        fi

        export ZSH_CONFIG="$HOME/.zshrc"

        try_catch "make_zsh_setup_temp_file" "handle_zsh_config_error"

        echo "Installing Oh My Zsh..."
        echo "This will replace your existing .zshrc file"
        echo "The existing .zshrc file will be backed up to .zshrc.pre-oh-my-zsh"
        if [ ! -d "$HOME/.oh-my-zsh" ]; then
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        else
            echo "Oh My Zsh is already installed."
        fi

        # ensuring curl, git, etc are installed again in case user migrated scripts via hard storage device
        echo "Installing essential tools and utilities... This may take a while..."
        if [ "$YES" = true ]; then
            APT_FLAG="-y "
        else
            APT_FLAG=""
        fi
        retry_wrapper "
            sudo apt install $APT_FLAG build-essential xclip curl wget git unzip zip vim tmux gnupg pass ffmpeg \
neovim python3-pip python3-venv bat btop pwgen jq moreutils
" "echo '!! Error: Failed to install essential utilities.'"

        echo "Updating and upgrading system packages..."
        retry_wrapper "sudo apt update && sudo apt upgrade -y" \
            "echo '!! Error: Failed to upgrade packages.'"
        echo "apt updated and upgraded"

        install_docker
        install_golang
        install_java
        install_nvm_node
        install_rust

        install_homebrew

        echo "Installing Homebrew sourced package(s)..."
        retry_wrapper "brew install --cask fzf playwright ngrok croc" \
            "echo '!! Error: Failed to install Homebrew casks.'"

        # Directory setup
        PROJECTS_DIR="$HOME/projects"
        TOOLS_DIR="$HOME/tools"

        for dir in "$PROJECTS_DIR" "$TOOLS_DIR"; do
            if [ ! -d "$dir" ]; then
                echo "Creating $dir directory..."
                mkdir -p "$dir"
            else
                echo "$dir directory already exists."
            fi
        done

        # Pull project repositories from GitHub
        echo "Cloning project repositories..."
        GITHUB_USERNAME="jaroszej"
        PROJECT_REPOS=(
            "zsh-config"
            "roszeSoftUtilitySuite"
        )

        for repo in "${PROJECT_REPOS[@]}"; do
            REPO_DIR="$PROJECTS_DIR/$repo"
            if [ ! -d "$REPO_DIR" ]; then
                echo "Cloning $repo into $REPO_DIR..."
                git clone "https://github.com/$GITHUB_USERNAME/$repo.git" "$REPO_DIR"
            else
                echo "Repository $repo already exists in $REPO_DIR."
            fi
        done

        echo ""
        echo "Stage 2 setup is complete. Configuring Zsh..."

        exit 0

    else
        wrapper_frame "$stagename" "!! Error: Failed to source needed files."
        exit 1
    fi
else
    wrapper_frame "$stagename" "!! Error: Failed to source helper file."
    exit 1
fi
