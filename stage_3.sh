#!/bin/bash

set -e

stagename="stage 3"

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
        if [[ "$SHELL" =~ .*/bin/zsh$ ]]; then
            echo "Zsh is the default shell."
        else
            echo "!! Error: Zsh is not the default shell. Please set Zsh as the default shell and re-run this script."
            exit 1
        fi

        ZSH_REPOS_DIR="$HOME/zsh_repos"
        if [ ! -d "$ZSH_REPOS_DIR" ]; then
            mkdir -p "$ZSH_REPOS_DIR"
        fi

        echo "Installing Znap..."
        ZNAP_DIR="$ZSH_REPOS_DIR/znap"
        export ZNAP_DIR
        if [ ! -d "$ZNAP_DIR" ]; then
            retry_wrapper "git clone --depth 1 https://github.com/marlonrichert/zsh-snap.git \"$ZNAP_DIR\"" \
                "echo '!! Error: Failed to install Znap.'"
            echo "Znap installed successfully."
        else
            echo "Znap is already installed."
        fi

        echo "Installing zsh-autocomplete..."
        ZSH_AUTOCOMPLETE_DIR="$ZSH_REPOS_DIR/marlonrichert/zsh-autocomplete"
        if [ ! -d "$ZSH_AUTOCOMPLETE_DIR" ]; then
            retry_wrapper "git clone --depth 1 https://github.com/marlonrichert/zsh-autocomplete.git \"$ZSH_AUTOCOMPLETE_DIR\"" \
                "echo '!! Error: Failed to install zsh-autocomplete.'"
            echo "zsh-autocomplete installed successfully."
        else
            echo "zsh-autocomplete is already installed."
        fi

        echo "Configuring ~/.zshrc for Znap, zsh-autocomplete, and custom user functions..."
        if ! grep -q "znap.zsh" ~/.zshrc; then
            cat << 'EOF' >> ~/.zshrc

# Load Znap
[[ -r $ZNAP_DIR/znap.zsh ]] && source $ZNAP_DIR/znap.zsh

# Load zsh-autocomplete
source $ZSH_AUTOCOMPLETE_DIR/zsh-autocomplete.plugin.zsh

export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Plugins
znap source zsh-users/zsh-completions
znap source zsh-users/zsh-syntax-highlighting
znap source sindresorhus/pure

# CLI Color Variables
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
# Bold text colors
BOLD_BLACK='\033[1;30m'
BOLD_RED='\033[1;31m'
BOLD_GREEN='\033[1;32m'
BOLD_YELLOW='\033[1;33m'
BOLD_BLUE='\033[1;34m'
BOLD_MAGENTA='\033[1;35m'
BOLD_CYAN='\033[1;36m'
BOLD_WHITE='\033[1;37m'
# Reset
RESET='\033[0m'

# Aliases
alias zshconfig="subl ~/.zshrc"
alias ohmyzsh="subl ~/.oh-my-zsh"
alias clr="clear"
alias reset="r"
alias rnm="removeNodeModules"

fn_tag() {
    echo -e "\${BLUE}Zshrc Fn\${RESET} \${WHITE}=>\${RESET} \${GREEN}\$1\${RESET}"
}

py_venv() {
    fn_tag "py_venv"
    echo -e "\${GREEN}Creating venv...\${RESET}"
    python3 -m venv venv
    if exists -d "./venv"; then
        echo -e "\${GREEN}Activating venv...\${RESET}"
        source venv/bin/activate
    else
        echo -e "\${RED}Error creating venv.\${RESET}"
    fi
}

exists() {
    local resource_type="\$1"
    local resource_name="\$2"

    if [[ -z "\$resource_type" || -z "\$resource_name" ]]; then
        echo "Usage: exists [-f|-d] <path>"
        return 1
    fi

    if [[ "\$resource_type" == "-f" && -f "\$resource_name" ]]; then
        return 0
    elif [[ "\$resource_type" == "-d" && -d "\$resource_name" ]]; then
        return 0
    else
        return 1
    fi
}

zsh_commands() {
    fn_tag "zsh_commands"
    case "$1" in
        "-p"|"--python")
            echo -e "${CYAN}Python commands:${RESET}"
            echo -e "${CYAN}py_main${RESET} - Run main.py script"
            echo -e "${CYAN}py_workingdir${RESET} - Create virtual environment"
            echo -e "${CYAN}wipe_venv${RESET} - Remove virtual environment"
            echo -e "${CYAN}add_requirements <args>${RESET} - Add args to requirements.txt -> args: <dependency>"
            echo -e "${CYAN}install_requirements${RESET} - Install requirements.txt"
            echo -e "${CYAN}remove_requirements <args>${RESET} - Remove args from requirements.txt -> args: <dependency>"
            ;;
        "-g"|"--git")
            echo -e "${CYAN}Git commands:${RESET}"
            echo -e "${CYAN}p${RESET} - Pull"
            echo -e "${CYAN}pull${RESET} - Pull"
            ;;
        "-n"|"--node")
            echo -e "${CYAN}Node commands:${RESET}"
            echo -e "${CYAN}nrb${RESET} - Build"
            echo -e "${CYAN}nrgu${RESET} - Get updates"
            echo -e "${CYAN}napi${RESET} - Start API"
            echo -e "${CYAN}ni${RESET} - Install"
            echo -e "${CYAN}ncv${RESET} - Cache verify"
            echo -e "${CYAN}checkNodeJSVersion${RESET} - Check Node.js version"
            ;;
        "-z"|"--zsh")
            echo -e "${CYAN}Zsh commands:${RESET}"
            echo -e "${CYAN}zsh_commands${RESET} - List available commands"
            echo -e "${CYAN}backupZshConfig${RESET} - Backup zsh config"
            echo -e "${CYAN}r${RESET} - Reload zsh config"
            echo -e "${CYAN}clr${RESET} - Clear screen"
            echo -e "${CYAN}stats${RESET} - Show top 20 commands"
            ;;
        *)
            echo -e "${CYAN}Usage: zsh_commands [-p|-g|-n|-z]${RESET}"
            echo -e "${CYAN}Options:${RESET}"
            echo -e "${CYAN}-p, --python${RESET} - Python commands"
            echo -e "${CYAN}-g, --git${RESET} - Git commands"
            echo -e "${CYAN}-n, --node${RESET} - Node commands"
            echo -e "${CYAN}-z, --zsh${RESET} - Zsh commands"
            ;;
    esac
}

wipe_venv() {
    fn_tag "wipe_venv"
    if exists -d "./venv"; then
        echo -e "\${YELLOW}Remove venv...\${RESET}"
        echo -e "\${CYAN}rm -rf ./venv\${RESET}"
        rm -rf ./venv
    else
        echo -e "\${RED}Directory ./venv not found.\${RESET}"
    fi
}

add_requirements() {
    fn_tag "add_requirements"
    if exists -f "requirements.txt"; then
        local args=""
        local skipped_args=""

        for arg in "\$@"; do
            if grep -Fxq "\$arg" "requirements.txt"; then
                skipped_args+="\$arg"
            else
                echo "\$arg" >> "requirements.txt"
                args+="\$arg"
            fi
        done

        args="\${args%, }"
        skipped_args="\${skipped_args%, }"

        if [[ -n "\$args" ]]; then
            echo -e "\${GREEN}Added the following requirements to requirements.txt:\${RESET} \$args"
        fi
        if [[ -n "\$skipped_args" ]]; then
            echo -e "\${YELLOW}Args already present in requirements.txt:\${RESET} \$skipped_args"
        fi
    else
        echo -e "\${YELLOW}Existing requirements.txt not found. Creating new requirements.txt\${RESET}"
        touch requirements.txt
        if exists -f "requirements.txt"; then
            echo -e "\${CYAN}Created requirements.txt\${RESET}"
            add_requirements "\$@"
        else
            echo -e "\${RED}Failed to create requirements.txt\${RESET}"
        fi
    fi
}

remove_requirements() {
    fn_tag "remove_requirements"
    if exists -f "requirements.txt"; then
        local removed=""
        local not_found_args=""

        if [[ "\$1" == "--all" || "\$1" == "-a" ]]; then
            : > 'requirements.txt'
            echo -e "\${CYAN}Removed all requirements from requirements.txt\${RESET}"
            return
        fi

        for arg in "\$@"; do
            if grep -Fxq "\$arg" requirements.txt; then
                sed -i "/^\$arg\$/d" requirements.txt
                removed+="\$arg"
            else
                not_found_args+="\$arg"
            fi
        done

        removed="\${removed%, }"
        not_found_args="\${not_found_args%, }"

        if [[ -n "\$removed" ]]; then
            echo -e "\${GREEN}Removed the following requirements from requirements.txt:\${RESET} \$removed"
        fi
        if [[ -n "\$not_found_args" ]]; then
            echo -e "\${YELLOW}Args not found in requirements.txt:\${RESET} \$not_found_args"
        fi
    else
        echo -e "\${YELLOW}Existing requirements.txt not found.\${RESET}"
    fi
}

py_main() {
    fn_tag "py_main"

    if exists -f "main.py"; then
        if [[ "\$1" == "--log" || "\$1" == "-l" ]]; then
            local log_dir="logs_\$(date +'%Y-%m-%d')"
            if ! exists -d "\$log_dir"; then
                mkdir "\$log_dir"
                echo -e "\${GREEN}Created log directory: \$log_dir\${RESET}"
            fi

            local log_file="\$log_dir/log_\$(date +'%Y-%m-%d_%H-%M-%S').log"

            python3 main.py >> "$log_file" 2>&1
            echo -e "\${GREEN}Log saved to: \$log_file\${RESET}"
        else
            python3 main.py
        fi
    else
        echo -e "\${RED}main.py not found.\${RESET}"
    fi
}

install_requirements() {
    fn_tag "install_requirements"
    if exists -f "requirements.txt"; then
        pip install -r requirements.txt
    else
        echo -e "\${RED}No requirements.txt found in this directory.\${RESET}\n\tRun 'add_requirements <args>' to create one."
    fi
}

gen_gitignore() {
    fn_tag "gen_gitignore"
    if [ -f ".gitignore" ]; then
        echo -e "\${YELLOW}File .gitignore already exists.\${RESET}"
    else
        cat > .gitignore << 'EOG'
# Python-specific ignores
__pycache__/
*.py[cod]
*.pyo
*.pyd
*.env
*.venv
env/
venv/
ENV/
env.bak/
venv.bak/

# SQLite database files
*.db
*.sqlite

# VSCode-specific ignores
.vscode/
*.code-workspace

# Byte-compiled and cached files
*.log
*.cache

# OS-specific ignores
.DS_Store
Thumbs.db
desktop.ini

# WSL temporary files
*~

# Ignore Python virtual environments in project directories
/venv/
/env/

# Ignore Node.js modules
*/node_modules/

EOG
        echo -e "\${GREEN} '.gitignore' created."
    fi
}

edit_config() {
    fn_tag "edit_config"
    if command -v code >/dev/null 2>&1; then
        code ~/.zshrc
    elif command -v subl >/dev/null 2>&1; then
        subl ~/.zshrc
    elif command -v nvim >/dev/null 2>&1; then
        nvim ~/.zshrc
    else command -v nano >/dev/null 2>&1; then
        nano ~/.zshrc
    fi
}

backupZshConfig() {
	fn_tag "backupZshConfig"
	if [[ -e "$HOME/.zshrc" ]]; then
		if [[ ! -d "$HOME/zsh_config" ]]; then
            echo -e ">> {YELLOW}INFO{RESET}: No {GREEN}zsh_config{RESET} directory found..."
            echo -e ">> {YELLOW}INFO{RESET}: Creating {GREEN}zsh_config{RESET} directory..."

			mkdir -p "$HOME/zsh_config"
			touch "$HOME/zsh_config/.gitignore"

            echo "zsh*" >> "$HOME/zsh_config/.gitignore"
			echo "" >> "$HOME/zsh_config/.gitignore"

            echo -e ">> {YELLOW}INFO{RESET}: {GREEN}zsh_config{RESET} directory created."
		fi
		if [[ ! -e "$HOME/zsh_config/.zshrc" ]]; then
            echo -e ">> {YELLOW}INFO{RESET}: Creating new {GREEN}zsh_config{RESET} copy..."
		fi

        echo -e ">> {YELLOW}INFO{RESET}: Copying {GREEN}~/.zshrc{RESET} to {GREEN}zsh_config/.zshrc{RESET}..."
		cp "$HOME/.zshrc" "$HOME/zsh_config/.zshrc"
        
		if [[ -e "$HOME/zsh_config/.zshrc" ]]; then
            echo -e ">> {YELLOW}INFO{RESET}: {GREEN}~/.zshrc{RESET} copied to {GREEN}zsh_config/.zshrc{RESET}."
        else
            echo -e ">> {RED}ERROR{RESET}: {GREEN}~/.zshrc{RESET} failed to copy to {GREEN}zsh_config/.zshrc{RESET}.\\You may need to manually copy {GREEN}~/.zshrc{RESET} to {GREEN}zsh_config/.zshrc{RESET}."
		fi

	else
        echo -e ">> {YELLOW}INFO{RESET}: {GREEN}~/.zshrc{RESET} not found. Is zsh installed?"
	fi
}

r() {
    backupZshConfig
    exec zsh
}

# node
checkNodeVersion() {
    fn_tag "checkNodeVersion"
    local ver=$(node -v 2>/dev/null)
    if [ $? -eq 0 ]; then
        return \"${ver:1:2}\"
    else
        return -1
    fi
}

removeNodeModules() {
	script_signal "removeNodeModules"
	if [[ -d "node_modules" ]]; then
        echo -e ">> {YELLOW}INFO{RESET}: Removing {GREEN}node_modules{RESET}. Please wait..."
		rm -rf node_modules
        if [[ ! -d "node_modules" ]]; then
            echo -e ">> {YELLOW}INFO{RESET}: {GREEN}node_modules{RESET} has been removed!"
        else
            echo -e ">> {RED}ERROR{RESET}: {GREEN}node_modules{RESET} failed to remove."
        fi
	else
        echo -e ">> {YELLOW}INFO{RESET}: {GREEN}node_modules{RESET} not found in this directory."
	fi
}

# git fns
gfap() {
    fn_tag "gfap"
    git fetch -all
    git pull
}

EOF
            echo "Znap and zsh-autocomplete configuration added to ~/.zshrc."
        else
            echo "Znap configuration already exists in ~/.zshrc."
        fi

        echo "Adding skip_global_compini=1 to ~/.zshenv for zsh-autocomplete..."
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
