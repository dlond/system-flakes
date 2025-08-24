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
Team practices are maintained in the [system-tools-practices](https://github.com/dlond/system-tools-practices) repository:
- Team standards: See `CLAUDE.md` in system-tools-practices
- Git workflow: See `workflows/git-workflow.yaml`
- Development practices: See `workflows/development-practices.yaml`

## Development Commands

This repository uses Nix Flakes for system configuration management. Key commands:

### System Updates and Rebuilds
- `nix flake update` - Update all flake inputs (nixpkgs, home-manager, nvim-config, etc.)
- `nish build` - Build configuration without switching (safe testing!)
- `darwin-rebuild build --flake .#mbp` - Alternative build command
- `darwin-rebuild switch --flake .#mbp` - Apply Darwin system configuration changes (macOS) - SUPERVISOR ONLY
- `home-manager switch --flake .#dlond@linux` - Apply Home Manager configuration (Linux)

### Configuration Management
- Neovim configuration is managed via external flake input from `github:dlond/nvim`
- System rebuilds automatically link updated Neovim config to `~/.config/nvim`
- Always commit `flake.lock` changes after running `nix flake update`

## Project Scope & Responsibilities

### What This Project Owns
- **System configuration**: Nix Darwin for macOS, Home Manager for Linux
- **Developer tools**: nvdev, git aliases (gwt-*, wt), shell functions
- **Collaborative environments**: tmuxp configurations (project-based)
- **Package management**: System-wide tools and languages
- **Shell environment**: zsh, direnv, starship configurations
- **Editor tools**: Integration scripts for nvim testing

### Tools We Provide
- **gwt-nav**: Interactive worktree switcher with fzf
- **gwt-new <issue>**: Create worktree from GitHub issue
- **gwt-done**: Safe worktree cleanup after PR merge
- **tmuxp-project**: Launch project-named tmux session
- **cstatus**: Live Claude usage monitoring (htop-like)
- **nvdev**: Test nvim configs in isolation

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

## Integration with Other Projects

### Dependencies
- **Consumes from nvim**: Configuration via flake input
- **Provides to nvim**: nvdev testing tool, LSP servers via Nix
- **Provides to all projects**: Git workflow aliases, development tools

### Cross-Project Coordination
When making changes that affect tools:
1. Consider impact on nvim testing workflow
2. Ensure git aliases work across all project types
3. Test tmuxp configs with actual Claude sessions
4. Verify LSP servers are available for nvim

## Important Workflows

When updating Neovim configuration:
1. Make changes in the separate `dlond/nvim` repository
2. Commit and push changes to GitHub
3. Run `nix flake update` to pull latest nvim-config
4. Rebuild system configuration
5. Commit updated `flake.lock`

## Git Workflow

This project follows the standardized git workflow documented in system-tools-practices.

**⚠️ CRITICAL REMINDER**: NEVER push directly to main! ALWAYS use worktrees and PRs. This is production configuration that affects all team members.

Key principles:
- Never work directly on main branch
- NEVER push directly to main (no exceptions for this repo!)
- Issue-driven development with `gh issue create`
- Always use worktrees for feature development (`gwt-new <issue-number>`)
- Complete cleanup after merge (`gwt-done`)

### Project Location Convention
- **All projects live in**: `~/dev/projects/`
- **Worktrees go in**: `~/dev/worktrees/<project-name>/<issue-number>-description`
- This includes system-flakes, nvim, system-tools-practices, and all other team projects

The workflow integrates with the git configuration in `home/modules/git.nix` which provides aliases and automation for:
- Worktree management (`gwt-new`, `gwt-done`, `gwt-clean`)
- GitHub CLI integration (`gpr`, `gpm`, `ghc`)
- Branch cleanup and maintenance
- Pre-push hooks to prevent direct pushes to main

## When No Active Issues (Stay Productive!)

Never be idle! If waiting for PR reviews or between tasks:

### Continuous Integration
- **Build test**: Run `nish build` - should ALWAYS build without errors
- **PR maintenance**: Keep all open PRs rebased against main
- **Flake updates**: Check if any inputs need updating with `nix flake update --dry-run`
- **Module verification**: Test individual modules still evaluate correctly

### Proactive Maintenance
- **Tool testing**: Verify gwt-*, nvdev, and other tools work correctly
- **tmuxp configs**: Test tmuxp-project launches properly
- **Dependency check**: Ensure all required packages are present
- **Performance**: Check rebuild times, optimize if needed
- **Documentation**: Update configuration comments and CLAUDE.md

### Quality Assurance
- Every PR should be:
  - Rebased on latest main
  - Building successfully with `nish build`
  - Tested for the specific feature/fix
  - Ready for immediate merge

## Development Practices

Claude Code instances should follow the development practices documented in the system-tools-practices repository.

This includes:
- Task management with TodoWrite for multi-step operations
- Tool usage patterns and batching for efficient operations
- Debugging approaches and common bug patterns
- Code quality standards and communication guidelines

## Claude-Specific Environment Notes

### Shell Environment Differences
- **Zoxide warnings**: Claude sessions may show zoxide configuration warnings that don't appear for human users
- **Fix deployment**: Changes to ~/.zshrc require `darwin-rebuild switch` to take effect for Claude (can't just source)
- **Environment variables**: Setting variables like `_ZO_DOCTOR=0` may not persist across command invocations

### Git Hook Enforcement
- **Pre-push hooks**: Templates in `~/.config/git/templates/hooks/` are correct but may not be in existing repos
- **Manual fix needed**: Run `git init` in existing repos to update hooks from templates
- **Verification**: Check `.git/hooks/pre-push` exists and has correct syntax

### PR Review Best Practices
- **Use API for comments**: `gh pr view --comments` is unreliable
- **Preferred method**: `gh api repos/<owner>/<repo>/pulls/<PR#>/comments`
- **Three comment types**: Issue comments, review comments, and reviews each have different endpoints