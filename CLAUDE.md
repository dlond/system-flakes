# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## References
- Team standards: `../CLAUDE.md`
- Git workflow: `../git-workflow.yaml`
- Development practices: `../development-practices.yaml`

## Development Commands

This repository uses Nix Flakes for system configuration management. Key commands:

### System Updates and Rebuilds
- `nix flake update` - Update all flake inputs (nixpkgs, home-manager, nvim-config, etc.)
- `darwin-rebuild switch --flake .#mbp` - Apply Darwin system configuration changes (macOS)
- `home-manager switch --flake .#dlond@linux` - Apply Home Manager configuration (Linux)

### Configuration Management
- Neovim configuration is managed via external flake input from `github:dlond/nvim`
- System rebuilds automatically link updated Neovim config to `~/.config/nvim`
- Always commit `flake.lock` changes after running `nix flake update`

## Architecture Overview

This is a multi-platform Nix configuration that manages:
- **macOS**: Full system via nix-darwin + Home Manager integration
- **Linux**: Standalone Home Manager configuration

### Directory Structure
- `flake.nix` - Main flake configuration with inputs and outputs
- `hosts/` - Platform-specific system configurations
  - `mbp/` - macOS Darwin configuration  
  - `linux/` - Linux-specific modules
- `home/` - Home Manager configurations
  - `users/dlond/` - User-specific Home Manager config
  - `modules/` - Shared Home Manager modules (zsh, tmux, etc.)
- `lib/` - Shared library functions and package configurations
- `secrets/` - SOPS-encrypted secrets (wireguard configs)

### Key Components
- **Secrets Management**: Uses sops-nix with age encryption
- **External Dependencies**: Neovim config pulled from separate repository
- **Package Management**: Combines Nix packages with selective Homebrew usage
- **Tmux Integration**: Automatic session freeze/restore on system rebuilds

### Configuration Targets
- `darwinConfigurations.mbp` - macOS system (aarch64-darwin)
- `homeConfigurations."dlond@linux"` - Linux home environment (aarch64-linux)

## Important Workflows

When updating Neovim configuration:
1. Make changes in the separate `dlond/nvim` repository
2. Commit and push changes to GitHub
3. Run `nix flake update` to pull latest nvim-config
4. Rebuild system configuration
5. Commit updated `flake.lock`