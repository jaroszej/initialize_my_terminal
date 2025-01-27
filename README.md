# initialize_my_terminal

---

## Development Environment Setup Scripts

This repository contains scripts to automate the setup of a development environment on Linux Ubuntu systems (the way I like it).

---

## Scripts

- `helper.sh`: Utility functions for error handling.
- `stage_1.sh`: Installs and configures Zsh.
- `stage_2.sh`: Installs development tools and utilities.
- `stage_3.sh`: Configures Zsh with Znap and plugins.
- `start.sh`: Orchestrates the setup process.
- `stage_<1-3>_error_handlers.sh`: Provides error messaging to guide manual script correction.

---

### Note: Ensure scripts have executable permission

```bash
# navigate to scripts
cd ./initialize_my_terminal

# grant executable permissions
chmod +x helper.sh start.sh \
stage_1.sh stage_2.sh stage_3.sh \
stage_1_error_handlers.sh stage_2_error_handlers.sh stage_3_error_handlers.sh
```

---

## Script Stages

### **Stage 1 (`stage_1.sh`)**:
- **Purpose**: Installs and configures **Zsh** as the default shell.
- **Key Steps**:
  1. Updates and upgrades system packages.
  2. Checks if **Zsh** is already installed; if not, it installs it.
  3. Handles installation errors and prompts the user to retry if the installation fails.
  4. Verifies the Zsh installation path and sets Zsh as the default shell.
  5. Attempts to automate the initial Zsh configuration.
  6. Switches to Zsh and prepares to run `stage_2.sh`.

---

### **Stage 2 (`stage_2.sh`)**:
- **Purpose**: Installs a suite of **development tools and utilities**.
- **Key Steps**:
  1. Prompts the user to skip the installation of specific tools.
  2. Installs the selected tools using package manager(s).
  3. Installs **Homebrew** and additional Homebrew casks.
  4. Sets up project directories.
  5. Clones GitHub repositories into the new directories.
  6. Installs essential system utilities.

---

### **Stage 3 (`stage_3.sh`)**:
- **Purpose**: Configures **Zsh** with **Znap** and additional plugins.
- **Key Steps**:
  1. Verifies that Zsh is installed and set as the default shell.
  2. Installs **Znap** (a Zsh plugin manager) if it’s not already installed.
  3. Configures the `.zshrc` file to load plugins and sets up helpful customer user functions.
  4. Completes the setup and notifies the user to restart the terminal for changes to take effect.
  5. Offers a reminder to set up gpg encryptions.

---

### **Helper Scripts**:
- **`helper.sh`**:
  - Provides utility functions for error handling.
  - Captures and logs the output of failed commands for debugging.

- **Error Handlers**:
  - **`stage_1_error_handlers.sh`**: Handles errors during Zsh installation.
  - **`stage_2_error_handlers.sh`**: Handles errors during the installation of development tools.
  - **`stage_3_error_handlers.sh`**: Handles errors during Zsh configuration and plugin installation.

---

### **Start Script (`start.sh`)**:
- **Purpose**: Orchestrates the execution of all stages.
- **Key Steps**:
  1. Sources the helper and error handler scripts.
  2. Runs each stage script in sequence.
  3. Handles errors and provides feedback if any stage fails.
  4. Outputs a success message upon completion of all stages.

---

## Overall Goal

- Zsh is installed and configured as the default shell to my taste.
- Essential development tools and utilities are installed.
- Zsh is enhanced with plugins for improved productivity (and style).
