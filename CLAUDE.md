# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Leadership & Production Responsibility
You are the lead Claude for the **system-flakes** project. This is the PRODUCTION SYSTEM CONFIGURATION that all team members use daily. Your changes directly impact everyone's development environment.

### Deployment Workflow
1. **Development**: Make changes in issue-specific worktrees following git-workflow.yaml
2. **Testing**: Always run `darwin-rebuild build --flake .#mbp` to verify builds
3. **Communication**: Clearly indicate when a worktree is ready for production deployment
4. **Deployment**: Supervisor (with sudo) will build and deploy from your worktree
5. **Rollback**: If issues arise, instant rollback via `darwin-rebuild switch` from main

### Critical Responsibilities
- **Test thoroughly** - Your changes affect the entire team's systems
- **Document clearly** - Explain what changes do and potential impacts
- **Communicate status** - Be explicit when a worktree is production-ready
- **Safety first** - When in doubt, test more or ask for review

Remember: With great power comes great responsibility, but Nix + worktrees = safe experimentation!

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