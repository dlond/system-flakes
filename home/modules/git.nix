{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.zsh.shellAliases = {
    # GitHub CLI workflow aliases
    gpr = "git push -u origin $(git branch --show-current) && gh pr create";
    gpv = "gh pr view";
    gpc = "gh pr checkout";
    gpm = "gh pr merge --delete-branch=false";
    gprs = "gh pr status";
    gprl = "gh pr list";
    gprd = "gh pr diff";

    # Issue management
    ghi = "gh issue list";
    ghv = "gh issue view";
    ghc = "gh issue create";

    # Repository shortcuts
    ghw = "gh repo view --web";
    gho = "gh browse";

    # Combined git workflow shortcuts
    gwip = "git add -A && git commit -m 'WIP: work in progress'";
    gsync = "git fetch origin && git rebase origin/main && git remote prune origin";
    gca = "git commit --amend";
    gcf = "git commit --fixup";

    # Branch cleanup
    gclean-merged = "git branch --merged main | grep -v main | xargs -n 1 git branch -d";
    gclean-remote = "git remote prune origin";
    gclean-all = "git fetch --prune && git branch --merged main | grep -v main | xargs -n 1 git branch -d";
  };

  programs.git = {
    enable = true;

    userName = "dlond";
    userEmail = "dlond@me.com";

    signing =
      {
        key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKDBuv1nRNSziTjf2UuGhFk7ftnDXOuMfew5FMeINM66";
        format = "ssh";
      }
      // lib.mkIf pkgs.stdenv.isDarwin {
        signer = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
      }
      // lib.mkIf pkgs.stdenv.isLinux {
        signer = "";
      };

    # Common aliases and extraConfig could be moved to common.nix
    aliases = {
      # Basic shortcuts
      co = "checkout";
      br = "branch";
      ci = "commit";
      st = "status";
      unstage = "reset HEAD --";
      last = "log -1 HEAD";

      # Worktree shortcuts
      wt = "worktree";
      wtl = "worktree list";
      wta = "worktree add";
      wtr = "worktree remove";
      wtp = "worktree prune";

      # Better logging
      lg = "log --oneline --graph --decorate";
      ll = "log --pretty=format:'%C(yellow)%h%Creset %C(blue)%ad%Creset %C(green)%an%Creset %s' --date=short";
      lp = "log --patch";

      # Diff shortcuts
      d = "diff";
      ds = "diff --staged";
      dn = "diff --name-only";

      # Difftool shortcuts
      dt = "difftool";
      dtd = "difftool --dir-diff"; # All files at once!
      dts = "difftool --staged";
      dtsd = "difftool --staged --dir-diff"; # All staged files at once
      mt = "mergetool";

      # Stash management
      sl = "stash list";
      sp = "stash pop";
      ss = "stash show";

      # Branch management
      bd = "branch -d";
      bD = "branch -D";
      ba = "branch -a";

      # Undo/recovery
      undo = "reset --soft HEAD~1";
      undoh = "reset --hard HEAD~1";
      uncommit = "reset --mixed HEAD~1";
    };

    extraConfig = {
      color.ui = true;
      commit.template = "${config.home.homeDirectory}/dev/projects/system-tools-practices/templates/commit-message.template";
      core.editor = "nvim";
      diff.tool = "nvimdiff";
      difftool.prompt = false;
      difftool."nvimdiff".cmd = "nvim -d \"$LOCAL\" \"$REMOTE\"";
      fetch.prune = true;
      fetch.pruneTags = true;
      init.defaultBranch = "main";
      init.templateDir = "${config.home.homeDirectory}/.config/git/templates";
      merge.ff = "only";
      merge.tool = "nvimdiff";
      mergetool.prompt = false;
      mergetool."nvimdiff".cmd = "nvim -d \"$LOCAL\" \"$REMOTE\" \"$MERGED\" -c 'wincmd J | wincmd ='";
      pull.prune = true;
      pull.rebase = true;
      push.default = "current";
      rebase.autoSquash = true;
      rebase.autoStash = true;
      rebase.updateRefs = true;
      rerere.autoupdate = true;
      rerere.enable = true;
    };
  };

  xdg.configFile."git/templates/hooks/commit-msg" = {
    text = ''
      #!/usr/bin/env bash

      msg_file="$1"
      msg="$(head -n1 "$msg_file")"

      if ! rg -q '^(feat|fix|docs|style|refactor|perf|test|chore|build|ci)(\([^)]+\))?: .+' <<< "$msg"; then
        echo "🚫 Commit message must start with a valid Conventional Commit prefix:"
        echo "   feat:, fix:, docs:, style:, refactor:, perf:, test:, chore:, build:, ci:"
        exit 1
      fi
    '';
    executable = true;
  };

  xdg.configFile."git/templates/hooks/pre-push" = {
    text = ''
      #!/usr/bin/env bash

      while read local_ref local_sha remote_ref remote_sha; do
        branch="''${remote_ref#refs/heads/}"
        if [[ "$branch" == "main" || "$branch" == "master" ]]; then
          echo "🚫 Direct pushes to '$branch' are blocked. Create a PR instead!"
          echo "Use: gh pr create --fill"
          exit 1
        fi
      done
    '';
    executable = true;
  };

  xdg.configFile."git/templates/.github/ISSUE_TEMPLATE/bug_report.md".text = ''
    ---
    name: Bug report
    about: Report a bug so we can fix it
    title: "[BUG] "
    labels: bug
    assignees: ""
    ---
    **Describe the bug**
    A clear and concise description.

    **Steps to reproduce**
    1. Go to '...'
    2. Click on '...'
    3. See error

    **Expected behaviour**
    What you expected to happen.

    **Screenshots/logs**
    If applicable, add screenshots or logs.

    **Environment**
    - OS:
    - Branch/commit:
    - Other relevant info:
  '';

  xdg.configFile."git/templates/.github/ISSUE_TEMPLATE/feature_request.md".text = ''
    ---
    name: Feature request
    about: Suggest an idea for this project
    title: "[FEATURE] "
    labels: enhancement
    assignees: ""
    ---

    **Describe the feature**
    A clear and concise description of what you want.

    **Why is it needed?**
    Explain the use case.

    **Additional context**
    Add any other context or mockups.
  '';

  xdg.configFile."git/templates/.github/ISSUE_TEMPLATE/config.yml".text = ''
    blank_issues_enabled: false
    contact_links:
      - name: Ask a question
        url: https://github.com/dlond/system-flakes/discussions
        about: Please ask and answer questions here.
  '';

  xdg.configFile."git/templates/.github/pull_request_template.md".text = ''
    ## Summary
    Briefly describe the changes.

    ## Related Issues
    Closes #<issue-number> <!-- or "Related to" -->

    ## Changes
    - [ ] Summary of major changes
    - [ ] Another change

    ## Checklist
    - [ ] I have rebased onto `main`
    - [ ] I have run all relevant tests/linters
    - [ ] I have updated documentation (if applicable)
  '';

  home.file.".local/bin/get-repo-templates" = {
    text = ''
      #!/usr/bin/env bash

      set -euo pipefail

      repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
      if [[ -z "$repo_root" ]]; then
        echo "Not in a git repo." >&2; exit 1
      fi

      src="$HOME/.config/git/templates/.github"
      dst="$repo_root"
      mkdir -p "$dst"
      rsync -a "$src" "$dst"
      echo "✅ Templates copied to $dst"
    '';
    executable = true;
  };

  # Shared library for gwt scripts
  home.file.".local/lib/gwt-common.sh" = {
    text = ''
      #!/usr/bin/env bash
      # Common functions for gwt (git worktree) scripts

      # Get the main branch name (main or master)
      get_main_branch() {
        git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main"
      }

      # Check if we're in a git repository
      check_git_repo() {
        if ! git rev-parse --git-dir >/dev/null 2>&1; then
          echo "Error: Not in a git repository" >&2
          return 1
        fi
      }

      # Get the project name from repo
      get_project_name() {
        local repo_url=$(git config --get remote.origin.url)
        basename -s .git "$repo_url"
      }

      # Get standard worktree base directory
      get_worktree_base() {
        local project_name=$(get_project_name)
        echo "$HOME/dev/worktrees/$project_name"
      }

      # Check if branch exists locally
      branch_exists() {
        local branch=$1
        git show-ref --verify --quiet "refs/heads/$branch"
      }

      # Check if worktree exists for branch
      worktree_exists() {
        local branch=$1
        git worktree list --porcelain | grep -q "branch refs/heads/$branch"
      }

      # Get worktree path for a branch
      get_worktree_path() {
        local branch=$1
        # Need to look BEFORE the branch line to find the worktree line
        git worktree list --porcelain | grep -B2 "branch refs/heads/$branch$" | grep "^worktree" | cut -d" " -f2
      }

      # Find branch by issue number
      find_branch_by_issue() {
        local issue_num=$1
        # Strip refs/heads/ prefix to get just the branch name
        git worktree list --porcelain | grep "^branch" | cut -d" " -f2 | grep -E "[-/]$issue_num([-/]|$)" | sed 's|^refs/heads/||' | head -1
      }

      # Extract issue numbers from branch name
      extract_issue_numbers() {
        local branch=$1
        # Match patterns like: fix-123-desc, feature-123-124-desc, 123-desc, etc.
        echo "$branch" | grep -oE '[0-9]+' | tr '\n' ' ' | sed 's/ $//'
      }

      # Sanitize string for branch name
      sanitize_for_branch() {
        echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g'
      }

      # Check if PR exists for branch
      pr_exists() {
        local branch=$1
        gh pr view "$branch" --json number >/dev/null 2>&1
      }

      # Get PR state
      get_pr_state() {
        local branch=$1
        local pr_status=$(gh pr view "$branch" --json state,mergedAt 2>/dev/null || echo '{"state":"UNKNOWN"}')
        echo "$pr_status" | jq -r '.state'
      }

      # Check if PR is merged
      is_pr_merged() {
        local branch=$1
        local pr_status=$(gh pr view "$branch" --json state,mergedAt 2>/dev/null || echo '{"state":"UNKNOWN"}')
        local pr_state=$(echo "$pr_status" | jq -r '.state')
        local pr_merged=$(echo "$pr_status" | jq -r '.mergedAt')

        [[ "$pr_state" == "MERGED" ]] || [[ "$pr_merged" != "null" ]]
      }

      # Check if branch is merged (via regular merge)
      is_branch_ancestor() {
        local branch=$1
        local target_branch=''${2:-$(get_main_branch)}
        git merge-base --is-ancestor "$branch" "$target_branch" 2>/dev/null
      }

      # Check if branch is merged by any method (regular, squash, or rebase)
      is_branch_merged() {
        local branch=$1
        local target_branch=''${2:-$(get_main_branch)}

        # First check: regular merge (fast, local)
        if is_branch_ancestor "$branch" "$target_branch"; then
          return 0
        fi

        # Second check: PR merged on GitHub (catches squash/rebase)
        if is_pr_merged "$branch"; then
          return 0
        fi

        return 1
      }

      # Get PR merge status with details
      get_pr_status() {
        local branch=$1
        local pr_status=$(gh pr view "$branch" --json state,mergedAt 2>/dev/null || echo '{"state":"UNKNOWN"}')
        echo "$pr_status"
      }

      # Colored output helpers
      print_error() {
        echo "❌ $*" >&2
      }

      print_success() {
        echo "✅ $*"
      }

      print_warning() {
        echo "⚠️  $*"
      }

      print_info() {
        echo "📍 $*"
      }

      print_working() {
        echo "🔄 $*"
      }
    '';
    executable = false;
  };

  home.file.".local/bin/gwt-new" = {
    text = ''
      #!/usr/bin/env bash
      # Create worktree for new feature/bugfix branch based on issue numbers or custom name

      set -euo pipefail

      # Source common functions
      source "$HOME/.local/lib/gwt-common.sh"

      usage() {
        echo "Usage: gwt-new [--cwd] <issue-number> [issue-number...] | gwt-new [--cwd] <branch-name>"
        echo ""
        echo "Options:"
        echo "  --cwd    Stay in current directory (don't cd to new worktree)"
        echo ""
        echo "Examples:"
        echo "  gwt-new 123                    # Single issue (cd to new worktree)"
        echo "  gwt-new --cwd 123              # Single issue (stay in current dir)"
        echo "  gwt-new 123 124 125            # Multiple issues (with analysis)"
        echo "  gwt-new custom-branch-name     # Custom branch name"
        exit 1
      }

      sanitize_title() {
        sanitize_for_branch "$1"
      }

      fetch_issue_info() {
        local issue_num=$1
        local info

        info=$(gh issue view "$issue_num" --json title,labels,body 2>/dev/null) || {
          echo "Error: Could not fetch issue #$issue_num" >&2
          return 1
        }

        echo "$info"
      }

      analyze_issues() {
        local issues=("$@")
        local titles=()
        local labels_all=()
        local keywords=()

        echo "Analyzing issues for compatibility..." >&2
        echo "" >&2

        # Fetch all issue data
        for issue in "''${issues[@]}"; do
          local info
          info=$(fetch_issue_info "$issue") || return 1

          local title
          title=$(echo "$info" | jq -r '.title')
          titles+=("$title")

          local labels
          labels=$(echo "$info" | jq -r '.labels[].name' | tr '\n' ' ')
          labels_all+=("$labels")

          echo "  #$issue: $title" >&2
          [ -n "$labels" ] && echo "    Labels: $labels" >&2
        done

        echo "" >&2

        # Simple compatibility analysis
        local common_words=()
        local component_labels=()
        local type_labels=()

        # Extract common keywords from titles
        for title in "''${titles[@]}"; do
          # Get significant words (>3 chars, common terms)
          words=$(echo "$title" | tr '[:upper:]' '[:lower:]' | grep -oE '\b[a-z]{4,}\b' | grep -E '(auth|user|login|api|ui|data|error|bug|fix|feature|improve)')
          keywords+=($words)
        done

        # Check for label consistency
        for labels in "''${labels_all[@]}"; do
          component_labels+=($(echo "$labels" | grep -oE '\b(frontend|backend|api|ui|auth|database)\b' || true))
          type_labels+=($(echo "$labels" | grep -oE '\b(bug|feature|enhancement|refactor)\b' || true))
        done

        # Suggest branch name based on analysis
        local suggested_name=""

        if [ ''${#issues[@]} -eq 1 ]; then
          # Single issue - use sanitized title
          suggested_name=$(sanitize_title "''${titles[0]}")-''${issues[0]}
        else
          # Multiple issues - analyze for common theme
          local common_component=""
          local common_type=""

          # Find most common component and type
          if [ ''${#component_labels[@]} -gt 0 ]; then
            common_component=$(printf '%s\n' "''${component_labels[@]}" | sort | uniq -c | sort -nr | head -1 | awk '{print $2}')
          fi

          if [ ''${#type_labels[@]} -gt 0 ]; then
            common_type=$(printf '%s\n' "''${type_labels[@]}" | sort | uniq -c | sort -nr | head -1 | awk '{print $2}')
          fi

          # Check for common keywords
          local common_keyword=""
          if [ ''${#keywords[@]} -gt 0 ]; then
            common_keyword=$(printf '%s\n' "''${keywords[@]}" | sort | uniq -c | sort -nr | head -1 | awk '{if($1>1) print $2}')
          fi

          # Build suggested name
          local name_parts=()
          [ -n "$common_component" ] && name_parts+=("$common_component")
          [ -n "$common_keyword" ] && name_parts+=("$common_keyword")
          [ -n "$common_type" ] && name_parts+=("$common_type")

          if [ ''${#name_parts[@]} -gt 0 ]; then
            suggested_name=$(IFS=-; echo "''${name_parts[*]}")-$(IFS=-; echo "''${issues[*]}")
          else
            suggested_name="combined-issues-$(IFS=-; echo "''${issues[*]}")"
          fi
        fi

        echo "$suggested_name"
      }

      create_worktree() {
        local branch_name=$1
        local stay_in_cwd=$2

        # Use common functions to get project info
        local project_name=$(get_project_name)
        local worktree_base=$(get_worktree_base)
        local folder_path="$worktree_base/$branch_name"

        echo "Creating worktree: $folder_path with branch: $branch_name"

        # Create the worktree base directory if it doesn't exist
        mkdir -p "$worktree_base"

        if [ -d "$folder_path" ]; then
          echo "Error: Directory $folder_path already exists" >&2
          return 1
        fi

        git worktree add "$folder_path" -b "$branch_name" || {
          echo "Error: Failed to create worktree" >&2
         return 1
        }

        echo "✅ Worktree created successfully!"
        echo "📁 Path: $folder_path"
        echo "🌿 Branch: $branch_name"
        
        # Run direnv allow if .envrc exists
        if [ -f "$folder_path/.envrc" ]; then
          echo "🔐 Running direnv allow..."
          (cd "$folder_path" && direnv allow)
        fi
        
        # Change to the new worktree unless --cwd was specified
        if [ "$stay_in_cwd" = "false" ]; then
          echo ""
          echo "📂 Switching to new worktree..."
          cd "$folder_path"
          # Since this is a script (not a function), we need to exec a new shell
          exec $SHELL
        else
          echo ""
          echo "To switch: cd $folder_path"
        fi
      }

      main() {
        if [ $# -eq 0 ]; then
          usage
        fi

        # Parse flags
        local stay_in_cwd=false
        local args=()
        
        while [[ $# -gt 0 ]]; do
          case $1 in
            --cwd)
              stay_in_cwd=true
              shift
              ;;
            *)
              args+=("$1")
              shift
              ;;
          esac
        done
        
        # Restore positional parameters
        set -- "''${args[@]}"
        
        if [ $# -eq 0 ]; then
          usage
        fi

        # Check if we're in a git repository
        check_git_repo || exit 1

        # Check if first argument is a number (issue) or string (custom branch)
        if [[ $1 =~ ^[0-9]+$ ]]; then
          # Issue number(s) provided
          local issues=("$@")
          local suggested_name

          suggested_name=$(analyze_issues "''${issues[@]}") || exit 1

          echo "💡 Suggested branch name: $suggested_name"
          echo ""

          if [ ''${#issues[@]} -gt 1 ]; then
            echo "⚠️  Multiple issues detected. Please verify they belong together:"
            echo "   • Are they related features/bugs?"
            echo "   • Same component or area of code?"
            echo "   • Similar complexity/timeline?"
            echo ""
          fi

          read -p "Use suggested name? (Y/n/custom): " -r response

          case "$response" in
            [nN]*)
              read -p "Enter custom branch name: " -r custom_name
              [ -n "$custom_name" ] && suggested_name="$custom_name"
              ;;
            [cC]*)
              read -p "Enter custom branch name: " -r custom_name
              [ -n "$custom_name" ] && suggested_name="$custom_name"
              ;;
          esac

          create_worktree "$suggested_name" "$stay_in_cwd"

        else
          # Custom branch name provided
          local branch_name=$1
          create_worktree "$branch_name" "$stay_in_cwd"
        fi
      }

      main "$@"
    '';
    executable = true;
  };

  # Git worktree shell functions (sourced by zsh.nix)
  home.file.".local/lib/gwt-functions.sh" = {
    text = ''
      #!/usr/bin/env bash
      # Git worktree functions - must be sourced to work properly

      # All gwt functions source the common library
      # These are functions (not scripts) so they can change directory and maintain consistency

      gwt-switch() {
        # Source common functions
        source "$HOME/.local/lib/gwt-common.sh"

        if [ $# -gt 0 ]; then
          echo "Usage: gwt-switch"
          echo ""
          echo "fzf-based worktree switcher."
          return 1
        fi

        # Check if we're in a git repository
        check_git_repo || return 1

        local current_wt=$(git rev-parse --show-toplevel 2>/dev/null)

        local all_wts=$(git worktree list --porcelain | awk '
          /^worktree / { path=$2 }
          /^branch / {
            branch=$2
            gsub("refs/heads", "", branch)
            if (branch == "") branch="(detached)"
            printf "%s\t%s\n", path, branch
          }
        ')

        local selected=$(echo "$all_wts" | fzf \
          --header="Select worktree (current: $(basename "$current_wt"))" \
          --preview="echo 'Path: {1}'; echo 'Branch: {2}'; echo '---'; ls -la {1} 2>/dev/null | head -20" \
          --preview-window=right:50%:wrap \
          --delimiter=$'\t' \
          --with-nth=2 \
          --bind='ctrl-d:reload(git worktree list --porcelain | awk "/^worktree / { path=\$2 } /^branch / { branch=\$2; gsub(\"refs/heads/\", \"\", branch); if (branch == \"\") branch=\"(detached)\"; printf \"%s\\t%s\\n\", path, branch }")' \
          --prompt="Worktree> " | cut -f1)

        # Navigate to selected worktree
        if [ -n "$selected" ]; then
          cd "$selected" || return 1
          print_info "Switched to: $(basename "$selected")"
          pwd
        fi
      }

      gwt-done() {
        # Source common functions
        source "$HOME/.local/lib/gwt-common.sh"

        # Helper function for usage
        usage() {
          echo "Usage: gwt-done [branch-name | issue-number] [--no-close]"
          echo ""
          echo "Options:"
          echo "  --no-close   Don't automatically close related issues"
          echo "  --help, -h   Show this help message"
          echo ""
          echo "Clean up worktree and branch after PR is merged."
          echo "Automatically closes related GitHub issues unless --no-close is specified."
          return 0
        }

        # Parse arguments
        local close_issues=true
        local arg=""

        while [[ $# -gt 0 ]]; do
          case $1 in
            --no-close)
              close_issues=false
              shift
              ;;
            --help|-h)
              usage
              return 0
              ;;
            *)
              if [ -z "$arg" ]; then
                arg="$1"
              fi
              shift
              ;;
          esac
        done

        # FIXED LOGIC: Always resolve issue/branch to target first
        local target_branch=""
        local current_branch=$(git branch --show-current)
        
        # If argument provided, use it
        if [ -n "$arg" ]; then
          if [[ "$arg" =~ ^[0-9]+$ ]]; then
            # It's an issue number - find the branch
            target_branch=$(find_branch_by_issue "$arg")
            if [ -z "$target_branch" ]; then
              print_error "No worktree found for issue #$arg"
              return 1
            fi
          else
            # It's a branch name
            target_branch="$arg"
          fi
        else
          # No argument - use current branch if not main
          if [[ "$current_branch" != "main" ]] && [[ "$current_branch" != "master" ]]; then
            target_branch="$current_branch"
          else
            echo "📍 In main worktree - specify a branch or issue number to clean up"
            usage
            echo ""
            echo "Available worktrees:"
            git worktree list | tail -n +2 | awk '{print "  • " $3 " at " $1}'
            return 1
          fi
        fi
        
        # Safety check: Never remove main branch
        local main_branch=$(get_main_branch)
        if [[ "$target_branch" == "$main_branch" ]] || [[ "$target_branch" == "main" ]] || [[ "$target_branch" == "master" ]]; then
          print_error "Cannot remove the main branch ($target_branch)!"
          return 1
        fi
        
        # Get worktree path for target branch
        local worktree_dir=$(get_worktree_path "$target_branch")
        if [ -z "$worktree_dir" ]; then
          echo "❌ No worktree found for branch: $target_branch"
          return 1
        fi
        
        # Always switch to main before removing
        if [[ "$current_branch" != "$main_branch" ]]; then
          local main_worktree=$(git worktree list | head -1 | awk '{print $1}')
          echo "🔄 Switching to main worktree: $main_worktree"
          cd "$main_worktree" || return 1
        fi

        # Pull merged changes
        echo "⬇️  Pulling merged changes..."
        git fetch origin
        git pull origin "$main_branch"

        # Check if the PR was merged (important for squash merges)
        echo "🔍 Checking if PR was merged..."

        if is_pr_merged "$target_branch"; then
          echo "✅ PR was merged"

          # Remove the worktree
          print_working "Removing worktree: $target_branch"
          git worktree remove "$worktree_dir" 2>/dev/null || {
            echo "⚠️  Could not remove worktree automatically"
            echo "   Run: git worktree remove \"$worktree_dir\" --force"
          }

          # Delete the local branch (use -D for squash-merged branches)
          print_working "Deleting local branch: $target_branch"
          git branch -D "$target_branch" 2>/dev/null || {
            echo "⚠️  Could not delete branch automatically"
            echo "   Branch may not exist locally or may be checked out elsewhere"
          }

          # Extract and close related issues (if enabled)
          if [ "$close_issues" = true ]; then
            local issue_numbers=$(extract_issue_numbers "$target_branch")
            if [ -n "$issue_numbers" ]; then
              print_working "Closing related issues: $issue_numbers"
              for issue in $issue_numbers; do
                # Check if issue exists and is open
                if [[ $(gh issue view "$issue" --json state -q .state 2>/dev/null) == "OPEN" ]]; then
                  if gh issue close "$issue" --comment "Closed automatically by gwt-done after PR merge" 2>/dev/null; then
                    print_success "Closed issue #$issue"
                  else
                    print_warning "Could not close issue #$issue"
                  fi
                else
                  echo "   Issue #$issue is already closed or doesn't exist"
                fi
              done
            fi
          else
            local issue_numbers=$(extract_issue_numbers "$target_branch")
            if [ -n "$issue_numbers" ]; then
              print_info "Skipping issue closing (--no-close specified) for: $issue_numbers"
            fi
          fi

          print_success "Worktree and branch cleanup complete!"

          # We're now safely in the main worktree
          pwd
        else
          print_warning "PR is not merged (state: $pr_state)"
          echo "   Please merge the PR first, then run gwt-done again"
          echo "   To force cleanup: git worktree remove \"$worktree_dir\" --force"
          return 1
        fi
      }
    '';
    executable = false;
  };

  # Note: gwt-done is now a shell function in gwt-functions.sh
  # because it needs to change directory when called from a worktree

  # Worktree cleanup - prune and remove merged branches
  home.file.".local/bin/gwt-clean" = {
    text = ''
      #!/usr/bin/env bash
      # Clean up stale worktrees and remove merged branches

      set -euo pipefail

      # Source common functions
      source "$HOME/.local/lib/gwt-common.sh"

      usage() {
        echo "Usage: gwt-clean [-f|--force]"
        echo ""
        echo "Options:"
        echo "  -f, --force   Force remove all worktrees except main/master"
        echo ""
        echo "Prunes stale worktrees and removes worktrees for merged branches."
        exit 1
      }

      main() {
        local force_mode=false

        # Parse arguments
        while [[ $# -gt 0 ]]; do
          case $1 in
            -f|--force)
              force_mode=true
              shift
              ;;
            -h|--help)
              usage
              ;;
            *)
              echo "Unknown option: $1"
              usage
              ;;
          esac
        done

        # Check if we're in a git repository
        check_git_repo || exit 1

        echo "🧹 Cleaning up worktrees..."

        # First, prune any stale worktrees
        echo "📦 Pruning stale worktrees..."
        git worktree prune -v

        # Get the main branch name
        main_branch=$(get_main_branch)

        if [ "$force_mode" = true ]; then
          echo "⚠️  Force mode: removing all worktrees except $main_branch"
          git worktree list --porcelain | grep "^worktree" | cut -d" " -f2 | while read -r wt_path; do
            # Skip the main worktree
            if [ "$wt_path" = "$(git rev-parse --show-toplevel)" ]; then
              continue
            fi
            echo "  Removing: $wt_path"
            git worktree remove "$wt_path" --force 2>/dev/null || echo "    ⚠️  Could not remove $wt_path"
          done
        else
          # Remove worktrees for merged branches
          echo "🔍 Checking for merged worktree branches..."
          local removed_count=0

          git worktree list --porcelain | awk '
            /^worktree / { path=$2 }
            /^branch / {
              branch=$2
              gsub("refs/heads/", "", branch)
              if (branch != "") printf "%s\t%s\n", path, branch
            }
          ' | while IFS=$'\t' read -r wt_path wt_branch; do
            # Skip the main worktree
            if [ "$wt_path" = "$(git rev-parse --show-toplevel)" ]; then
              continue
            fi

            # Check if branch is merged (any method)
            if is_branch_merged "$wt_branch" "$main_branch"; then
              # Determine merge type for user feedback
              if is_branch_ancestor "$wt_branch" "$main_branch"; then
                echo "  ✅ Merged branch found (regular merge): $wt_branch"
              else
                echo "  ✅ Merged branch found (squash/rebase merge): $wt_branch"
              fi
              echo "     Removing worktree: $wt_path"
              if git worktree remove "$wt_path" 2>/dev/null; then
                ((removed_count++))
                # Also try to delete the branch (use -D for squash-merged branches)
                git branch -D "$wt_branch" 2>/dev/null || true
              else
                echo "     ⚠️  Could not remove automatically (may have uncommitted changes)"
                echo "     Run: git worktree remove \"$wt_path\" --force"
              fi
            fi
          done

          if [ "$removed_count" -eq 0 ]; then
            echo "✨ No merged worktrees to clean up"
          else
            echo "✅ Cleaned up $removed_count worktree(s)"
          fi
        fi

        # List remaining worktrees
        echo ""
        echo "📍 Remaining worktrees:"
        git worktree list | awk '{print "  • " $3 " at " $1}'
      }

      main "$@"
    '';
    executable = true;
  };
}
