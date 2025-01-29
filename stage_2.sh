#!/bin/bash

set -e

installs_textwall() {
    echo ""
    echo "Press 'c' to continue and install all components, or enter numbers to skip specific installations (e.g., '1 3 5')."
    echo ""
    echo "Options:"
    echo "[1] Docker and Docker Compose"
    echo "[2] Golang"
    echo "[3] Java"
    echo "[4] NVM and the latest Node.js LTS version"
    echo "[5] Rust"
    echo "[0] Skip all installations"
    echo ""
}

prompt_skip_installs() {
    while true; do
        installs_textwall
        read -r skip_tools

        if [[ "$skip_tools" =~ ^[cC]$ ]]; then
            to_skip="c"
            break
        fi

        to_skip=""
        invalid_input=false
        for num in $skip_tools; do
            case "$num" in
                0)
                    to_skip="all"
                    break
                    ;;
                1|2|3|4|5)
                    to_skip+="$num "
                    ;;
                *)
                    echo "!! Error: Invalid option: $num"
                    invalid_input=true
                    ;;
            esac
        done

        if [ "$invalid_input" = false ]; then
            break
        else
            echo "Please try again."
        fi
    done

    # Trim trailing whitespace from to_skip
    to_skip="${to_skip%"${to_skip##*[![:space:]]}"}"

    echo "$to_skip"
}

install_docker() {
    echo "Installing Docker and Docker Compose..."
    try_catch \
        "sudo apt update && sudo apt install -y docker.io docker-compose" \
        handle_docker_error
    sudo systemctl start docker
    sudo systemctl enable docker
    echo "Docker installed successfully: $(docker --version)"
}

install_golang() {
    echo "Installing Golang..."
    try_catch \
        "sudo apt update && sudo apt install -y golang" \
        handle_golang_error
    echo "Golang installed successfully: $(go version)"
}

install_java() {
    echo "Installing Java..."
    try_catch \
        "sudo apt update && sudo apt install -y openjdk-17-jdk" \
        handle_java_error
    echo "Java installed successfully: $(java -version)"
}

# Install NVM, Node.js, and pnpm
install_nvm_node() {
    echo "Installing NVM..."
    if [ ! -d "$HOME/.nvm" ]; then
        try_catch \
            "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash" \
            handle_nvm_error
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
    try_catch \
        "nvm install --lts" \
        handle_node_error
    echo "Node.js LTS installed successfully: $(node -v)"

    echo "Installing pnpm..."
    try_catch \
        "npm install -g pnpm" \
        handle_pnpm_error
    echo "pnpm installed successfully: $(pnpm -v)"
}

install_rust() {
    echo "Installing Rust..."
    try_catch \
        "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y" \
        handle_rust_error
    echo "Rust installed successfully: $(rustc --version)"
}

install_homebrew() {
    echo "Installing Homebrew..."
    try_catch \
        "/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"" \
        handle_homebrew_error
    echo "Homebrew installed successfully: $(brew --version)"

    # Add Homebrew to the shell environment
    echo >> "$ZSH_CONFIG"
    echo "# Homebrew" >> "$ZSH_CONFIG"
    echo "eval '$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)'" >> ~/.zshrc
    eval '$(/opt/homebrew/bin/brew shellenv)'

    # shellcheck disable=SC1090
    source "$ZSH_CONFIG"
}

## Main logic ##
# Verify .zshrc exists
if [ ! -f "$HOME/.zshrc" ]; then
    echo "!! Error: .zshrc file was not created. Please run Zsh manually to complete configuration."
    exit 1
fi

export ZSH_CONFIG="$HOME/.zshrc"

# Create a flag file to indicate Zsh setup completion
touch /tmp/zsh_installed

echo "Installing Oh My Zsh..."
echo "This will replace your existing .zshrc file"
echo "The existing .zshrc file will be backed up to .zshrc.pre-oh-my-zsh"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "Oh My Zsh is already installed."
fi

# ensuring curl, git, wget are installed again in case user migrated scripts via hard storage device
echo "Installing essential tools and utilities..."
sudo apt install -y \
    build-essential \
    xclip \
    curl \
    wget \
    git \
    unzip \
    zip \
    vim \
    tmux \
    gnupg \
    pass \
    ffmpeg \
    neovim \
    python3-pip \
    python3-venv \
    bat \
    btop \
    pwgen \
    jq \
    moreutils 

echo "Updating and upgrading system packages..."
sudo apt update && sudo apt upgrade -y
echo "apt updated and upgraded"

installs_textwall
skipping=$(prompt_skip_installs)

if [ "$skipping" = "c" ]; then
    echo "Installing all components."
else
    while true; do
        if [ "$skipping" = "all" ]; then
            read -r -p "You chose to skip all installations. Are you sure? (y/n): " confirm
        else
            echo "You chose to skip: $skipping"
            read -r -p "Are you sure you want to skip these installations? (y/n): " confirm
        fi

        confirm="$(echo "$confirm" | tr '[:upper:]' '[:lower:]')"
        if [ "$confirm" = "y" ]; then
            break
        elif [ "$confirm" = "n" ]; then
            echo "Let's try again."
            skipping=$(prompt_skip_installs)
            if [ -z "$skipping" ]; then
                echo "Continuing to installs..."
                break
            fi
        else
            echo "Invalid input. Please answer with 'y' or 'n'."
        fi
    done
fi

if [ "$skipping" = "all" ]; then
    SKIP_ALL=true
else
    for val in $skipping; do
        case "$val" in
            1)
                SKIP_DOCKER=true
                ;;
            2)
                SKIP_GOLANG=true
                ;;
            3)
                SKIP_JAVA=true
                ;;
            4)
                SKIP_NODE=true
                ;;
            5)
                SKIP_RUST=true
                ;;
        esac
    done
fi

# Install tools based on flags
if [ "$SKIP_ALL" = true ]; then
    echo "Skipping all installations."
else
    [ "$SKIP_DOCKER" != true ] && install_docker
    [ "$SKIP_GOLANG" != true ] && install_golang
    [ "$SKIP_JAVA" != true ] && install_java
    [ "$SKIP_NODE" != true ] && install_nvm_node
    [ "$SKIP_RUST" != true ] && install_rust
fi

# Install Homebrew after all other tools
install_homebrew

echo "Installing Homebrew sourced package(s)..."
try_catch \
    "brew install --cask fzf playwright ngrok croc" \
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
