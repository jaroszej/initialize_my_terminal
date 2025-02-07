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
    docker_packages=("docker.io" "docker-compose")

    for package in "${docker_packages[@]}"; do
        retry_wrapper "install_necessary_package $package $APT_FLAG" "handle_docker_error $package"
    done

    sudo systemctl start docker
    sudo systemctl enable docker
    echo "Docker installed successfully: $(docker --version)"
    echo ""
}

install_golang() {
    echo "Installing Golang..."
    retry_wrapper "install_necessary_package golang -y" "handle_golang_error"
    echo "Golang installed successfully: $(go version)"
    echo ""
}

install_java() {
    echo "Installing Java..."
    java_version="openjdk-17-jdk"
    retry_wrapper "install_necessary_package $java_version -y" "handle_java_error"
    echo "Java installed successfully: $(java -version)"
    echo ""
}

# Install NVM, Node.js, and pnpm
install_nvm_node() {
    if ! check_nvm_installed_temp_file; then
        echo "Installing NVM..."
        if [ ! -d "$NVM_DIR" ]; then
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash;
            export NVM_DIR="$HOME/.nvm";
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh";
            [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion";
            source "$zsh_config"
            make_nvm_installed_temp_file
        else
            echo "NVM is already installed: v$(nvm --version)"
            nvm_installed=true
            make_nvm_installed_temp_file
        fi

        # Explicitly source nvm again to ensure it's available
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

        if [ "$nvm_installed" ] || [ "$(command -v nvm >/dev/null 2>&1)" ]; then
            echo "NVM installed: v$(nvm --version)"
        else
            echo "!! Error: NVM installation failed or is not found in PATH. Please verify your NVM installation by checking for the NVM directory at $NVM_DIR"
            exit 1
        fi
    else
        echo "NVM is installed."
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
    fi
}

install_rust() {
    RUST_ENV_FILE="$HOME/.cargo/env"
    if [ ! -f "$RUST_ENV_FILE" ]; then
        echo "Installing Rust..."    
        retry_wrapper "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y" "handle_rust_error"
        
        if [ -f "$RUST_ENV_FILE" ]; then
            # shellcheck disable=SC1091
            source "$RUST_ENV_FILE"
            echo "Rust installed successfully: $(rustc --version)"
        else
            echo "NOTE: $RUST_ENV_FILE not found after installation."
            echo "Try restarting your shell or manually running: source ~/.cargo/env"
        fi
    else
        echo "Rust already installed."
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
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
        echo "!! Error: Homebrew installation failed."
        exit 1
    }

    echo "Configuring Homebrew environment..."
    {
        echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
    } | tee -a "$bash_config" "$zsh_config" > /dev/null

    refresh_shell

    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" || {
        echo "!! Error: Failed to initialize Homebrew shell environment."
        exit 1
    }
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

        priority_packages=(
            "build-essential"
            "make"
            "gcc"
            "xclip"
            "curl"
            "wget"
            "git"
            "unzip"
            "zip"
            "vim"
            "tmux"
            "gnupg"
            "pass"
            "python3-pip"
            "python3-venv"
        )

        optional_packages=(
            "ffmpeg"
            "neovim"
            "bat"
            "btop"
            "pwgen"
            "jq"
            "moreutils"
            "fzf"
        )

        for package in "${priority_packages[@]}"; do
            try_catch \
                "install_necessary_package $package $APT_FLAG" \
                "echo 'NOTE: This is a blocking error. You may need to manually install $package and then rerun the script'"
        done

        for package in "${optional_packages[@]}"; do
            try_catch \
                "install_optional_package $package $APT_FLAG" \
                "echo 'NOTE: This is a non-blocking error. You may continue without $package installed. View failed optional packages in $OPTIONAL_PKG_LOG'"
        done

        echo "Updating and upgrading system packages..."
        aptuu=$(retry_wrapper "sudo apt update && sudo apt upgrade -y" \
            "echo '!! Error: Failed to upgrade packages.'")
        if [ "$aptuu" -eq 0 ]; then
            echo "apt updated and upgraded"
        fi

        aupa=$(retry_wrapper "sudo apt autoremove -y" \
            "echo '!! Error: Failed to autoremove packages.'")
        if [ "$aupa" -eq 0 ]; then
            echo "cleaned up apt packages that are 'no longer required'"
        fi

        install_java
        install_golang
        install_docker
        # install_nvm_node 
        install_rust

        install_homebrew

        # echo "Installing Homebrew sourced package(s)..."
        # homebrew_casks=("ngrok" "croc")

        # for cask in "${homebrew_casks[@]}"; do
        #     retry_wrapper "brew install --cask $cask" \
        #         "echo '!! Error: Failed to install Homebrew cask $cask.'; exit 1;"
        # done

        if [ "$WSL_DISTRO_NAME" ]; then
            echo "Detected WSL distro: $WSL_DISTRO_NAME. Configuring Wayland socket environment variables..."

            wayland_display='export WAYLAND_DISPLAY=wayland-0'
            runtime_dir='export XDG_RUNTIME_DIR=/mnt/wslg/runtime-dir'

            if ! grep -q "$wayland_display" "$ZSH_CONFIG"; then
                echo "$wayland_display" >> "$ZSH_CONFIG"
            else
                echo "wayland display set up in $ZSH_CONFIG"
            fi

            if ! grep -q "$runtime_dir" "$ZSH_CONFIG"; then
                echo "$runtime_dir" >> "$ZSH_CONFIG"
            else
                echo "runtime dir set up in $ZSH_CONFIG"
            fi            
            if grep -q '^ZSH_THEME=' ~/.zshrc; then
                sed -i 's/^ZSH_THEME=.*/ZSH_THEME="jonathan"/' ~/.zshrc
            else
                echo 'ZSH_THEME="jonathan"' >> ~/.zshrc
            fi
        fi

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

        # TODO: user prompted for username and pass here- investigate

        for repo in "${PROJECT_REPOS[@]}"; do
            REPO_DIR="$PROJECTS_DIR/$repo"
            if [ ! -d "$REPO_DIR" ]; then
                echo "Cloning $repo into $REPO_DIR..."
                git clone "git@github.com:$GITHUB_USERNAME/$repo.git" "$REPO_DIR"
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
