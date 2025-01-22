# initialize_my_terminal

---

## Development Environment Setup Scripts

This repository contains scripts to automate the setup of a development environment on Linux systems.

---

## Scripts

- `helper.sh`: Utility functions for error handling.
- `stage_1.sh`: Installs and configures Zsh.
- `stage_2.sh`: Installs development tools and utilities.
- `stage_3.sh`: Configures Zsh with Antigen and plugins.
- `start.sh`: Orchestrates the setup process.
- `stage_<1-3>_error_handlers.sh`: Provides error messaging to guide manual script correction.

---

## Script Stages

### **Stage 1 (`stage_1.sh`)**:
- **Purpose**: Installs and configures **Zsh** as the default shell.
- **Key Steps**:
  1. Updates and upgrades system packages using `apt`.
  2. Checks if **Zsh** is already installed; if not, it installs it.
  3. Handles installation errors and prompts the user to retry if the installation fails.
  4. Verifies the Zsh installation path and sets Zsh as the default shell using `chsh`.
  5. Automates the initial Zsh configuration (e.g., creating `.zshrc` if it doesn't exist).
  6. Switches to Zsh and prepares to run `stage_2.sh`.

---

### **Stage 2 (`stage_2.sh`)**:
- **Purpose**: Installs a suite of **development tools and utilities**.
- **Key Steps**:
  1. Prompts the user to skip the installation of specific tools (e.g., Docker, Golang, Java, Node.js, Rust).
  2. Installs the selected tools using `apt`, `curl`, or other package managers.
  3. Installs **Homebrew** and additional Homebrew casks (e.g., `fzf`, `playwright`).
  4. Sets up project directories (e.g., `~/projects`, `~/tools`).
  5. Clones GitHub repositories into the `~/projects` directory.
  6. Installs essential system utilities (e.g., `curl`, `git`, `vim`, `tmux`, `ffmpeg`).

---

### **Stage 3 (`stage_3.sh`)**:
- **Purpose**: Configures **Zsh** with **Antigen** and additional plugins.
- **Key Steps**:
  1. Verifies that Zsh is installed and set as the default shell.
  2. Installs **Antigen** (a Zsh plugin manager) if it’s not already installed.
  3. Configures Antigen in the `.zshrc` file to load plugins like:
     - `zsh-completions` (for better tab completion).
     - `zsh-syntax-highlighting` (for syntax highlighting in the shell).
  4. Completes the setup and notifies the user to restart the terminal for changes to take effect.

---

### **Helper Scripts**:
- **`helper.sh`**:
  - Provides utility functions (`try_catch` and `try_catch_finally`) for error handling.
  - Captures and logs the output of failed commands for debugging.

- **Error Handlers**:
  - **`stage_1_error_handlers.sh`**: Handles errors during Zsh installation.
  - **`stage_2_error_handlers.sh`**: Handles errors during the installation of development tools (e.g., Docker, Golang, Java, Node.js, Rust, Homebrew).
  - **`stage_3_error_handlers.sh`**: Handles errors during Zsh configuration and plugin installation.

---

### **Start Script (`start.sh`)**:
- **Purpose**: Orchestrates the execution of all stages.
- **Key Steps**:
  1. Sources the helper and error handler scripts.
  2. Runs each stage script (`stage_1.sh`, `stage_2.sh`, `stage_3.sh`) in sequence.
  3. Handles errors and provides feedback if any stage fails.
  4. Outputs a success message upon completion of all stages.

---

## Overall Goal

These scripts automate the setup of a **development environment** on a Linux Ubuntu system, ensuring that:
- Zsh is installed and configured as the default shell.
- Essential development tools and utilities are installed.
- Zsh is enhanced with plugins for improved productivity.
