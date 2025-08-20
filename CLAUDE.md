# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Leadership & Production Responsibility
You are the lead Claude for the **system-flakes** project. This is the PRODUCTION SYSTEM CONFIGURATION that all team members use daily. Your changes directly impact everyone's development environment.

### Deployment Workflow
1. **Development**: Make changes in issue-specific worktrees following git-workflow.yaml
2. **Testing**: Run `darwin-rebuild build --flake .#mbp` to verify builds (you can build but NOT switch - no sudo)
3. **Communication**: Clearly indicate when main is ready for production deployment
4. **Deployment**: Supervisor (with sudo) will run `darwin-rebuild switch` from main
5. **Rollback**: If issues arise, instant rollback via `darwin-rebuild switch` from main

### Critical Responsibilities
- **Test thoroughly** - Your changes affect the entire team's systems
- **Document clearly** - Explain what changes do and potential impacts
- **Communicate status** - Be explicit when main is production-ready after merges
- **Safety first** - When in doubt, test more or ask for review

**Important**: You don't have sudo access. Your supervisor handles the actual production deployments.

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

## Git Workflow

This project follows the standardized git workflow documented at: `../git-workflow.yaml`

Key principles:
- Never work directly on main branch
- Issue-driven development with `gh issue create`
- Always use worktrees for feature development (`gwt-new <issue-number>`)
- Complete cleanup after merge (`gwt-done`)

The workflow integrates with the git configuration in `home/modules/git.nix` which provides aliases and automation for:
- Worktree management (`gwt-new`, `gwt-done`, `gwt-clean`)
- GitHub CLI integration (`gpr`, `gpm`, `ghc`)
- Branch cleanup and maintenance
- Pre-push hooks to prevent direct pushes to main

## Development Practices

Claude Code instances should follow the development practices documented at: `../development-practices.yaml`

This includes:
- Task management with TodoWrite for multi-step operations
- Tool usage patterns and batching for efficient operations
- Debugging approaches and common bug patterns
- Code quality standards and communication guidelines