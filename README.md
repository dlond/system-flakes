# System Flakes

A comprehensive Nix flakes configuration for macOS (via nix-darwin) and Linux (via home-manager), with reusable development shells for multiple programming languages.

## Features

- 🖥️ **Full system configuration** for macOS with nix-darwin
- 🏠 **Home-manager** for Linux and macOS user environments
- 🚀 **Instant project scaffolding** with `nix-init-project`
- 📦 **Reusable dev shells** for Python, C++, Rust, and LaTeX
- 🔧 **Centralized package management** - single source of truth
- 🎯 **Neovim integration** with project-specific LSP/DAP configuration

## Quick Start

### System Installation

```bash
# Clone the repository
git clone https://github.com/dlond/system-flakes
cd system-flakes

# For macOS (nix-darwin)
darwin-rebuild switch --flake .#mbp

# For Linux (home-manager only)
home-manager switch --flake .#linux
```

### Creating New Projects

After system installation, use `nix-init-project` to scaffold any project:

```bash
# Create a Python project with specific version
nix-init-project python --name my-ml-project --python-version 3.12 --molten --jupyter

# Create a C++ project with C++23 and Clang 19
nix-init-project cpp --name my-app --cpp-standard 23 --compiler clang --compiler-version 19 --cmake

# Create a Rust project with WASM support
nix-init-project rust --name my-wasm-app --wasm

# Create a LaTeX document
nix-init-project latex --name my-paper --pandoc --scheme full

# See available options for each language
nix-init-project python --help
nix-init-project cpp --help
nix-init-project rust --help
nix-init-project latex --help
```

Each command creates:
- `flake.nix` - Nix development environment
- `.envrc` - Automatic environment activation with direnv
- `.gitignore` - Language-specific ignores
- `.nvim.lua` - Project-specific Neovim configuration
- Starter files (requirements.txt, CMakeLists.txt, Cargo.toml, main.tex)

## Updating Neovim & Flake Inputs

This flake manages the system configuration and pulls in the Neovim configuration from a separate repository ([dlond/nvim](https://github.com/dlond/nvim)) via a flake input (`nvim-config`).

This workflow assumes you are updating both your Neovim configuration and your general flake inputs (like `nixpkgs`, `home-manager`, etc.) at the same time.

1.  **Modify Neovim Config (If Applicable):**
    * Make any desired changes within your local clone of the `dlond/nvim` repository.
    * Commit and push these changes to the `dlond/nvim` repository on GitHub.
        ```bash
        # Navigate to your local nvim config repo
        cd path/to/your/local/dlond/nvim 
        
        # Stage, commit, and push
        git add .
        git commit -m "feat(nvim): description of changes" 
        git push origin main # Or your default branch
        ```

2.  **Update All Flake Inputs & Lock File:**
    * Navigate back to your main system configuration repository (`~/system-flakes`).
    * Run `nix flake update`. This command fetches the latest versions for *all* inputs defined in your `flake.nix` (including `nixpkgs`, `home-manager`, and `nvim-config` pointing to the commit you just pushed) and updates the `flake.lock` file accordingly.
        ```bash
        cd ~/system-flakes 
        nix flake update
        ```

3.  **Rebuild System Configuration:**
    * Apply the changes by rebuilding your Nix Darwin system. This fetches the updated sources based on the new lock file and links the latest Neovim config into `~/.config/nvim`.
        ```bash
        darwin-rebuild switch --flake .#mbp 
        ```
    * *(Replace `mbp` with your actual host name if different)*

4.  **Commit & Push Updated Lock File:**
    * Commit the modified `flake.lock` file to your `system-flakes` repository to record the updated dependencies.
        ```bash
        git add flake.lock
        git commit -m "feat: update flake inputs (including nvim)" # Updated commit message
        git push
        ```

Your system will now use the updated Neovim configuration and the latest versions of your other flake inputs.
