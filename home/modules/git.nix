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

    # Worktree navigation - removed, now a function in zsh.nix

    # Worktree complete cleanup after PR merge
    gwt-done = ''
      # Check if we have an argument (branch name or issue number)
      target_branch=""
      if [ -n "$1" ]; then
        # If it's a number, find the matching branch
        if [[ "$1" =~ ^[0-9]+$ ]]; then
          # Find worktree branch containing this issue number
          target_branch=$(git worktree list --porcelain | grep "^branch" | cut -d" " -f2 | grep -E "[-/]$1([-/]|$)" | head -1)
          if [ -z "$target_branch" ]; then
            echo "❌ No worktree found for issue #$1"
            exit 1
          fi
        else
          target_branch="$1"
        fi
      fi

      current_branch=$(git branch --show-current)
      current_dir=$(pwd)

      # jump to repo root so the rest of the script is always at the top level
      cd "$(git rev-parse --show-toplevel)"

      # Check if we're in a worktree (not the main repo)
      if git rev-parse --show-superproject-working-tree >/dev/null 2>&1; then
        echo "📦 In worktree: $current_branch"
        target_branch="$current_branch"
        worktree_dir="$current_dir"

        # Navigate to main worktree
        main_worktree=$(git worktree list | head -1 | awk '{print $1}')
        echo "🔄 Switching to main worktree: $main_worktree"
        cd "$main_worktree"
      elif [ -n "$target_branch" ]; then
        # We're in main and have a target branch
        echo "🎯 Cleaning up worktree: $target_branch"
        
        # Find the worktree directory for this branch
        worktree_dir=$(git worktree list --porcelain | grep -A1 "branch refs/heads/$target_branch" | grep "^worktree" | cut -d" " -f2)
        if [ -z "$worktree_dir" ]; then
          echo "❌ No worktree found for branch: $target_branch"
          exit 1
        fi
      else
        # In main with no target specified
        echo "📍 In main worktree - specify a branch or issue number to clean up"
        echo "Usage: gwt-done [branch-name | issue-number]"
        echo ""
        echo "Available worktrees:"
        git worktree list | tail -n +2 | awk '{print "  • " $3 " at " $1}'
        exit 0
      fi

      # Pull merged changes
      echo "⬇️  Pulling merged changes..."
      git fetch origin
      git pull origin main

      # Check if the PR was merged (important for squash merges)
      echo "🔍 Checking if PR was merged..."
      pr_status=$(gh pr view "$target_branch" --json state,mergedAt 2>/dev/null || echo '{"state":"UNKNOWN"}')
      pr_state=$(echo "$pr_status" | jq -r '.state')
      pr_merged=$(echo "$pr_status" | jq -r '.mergedAt')

      if [[ "$pr_state" == "MERGED" ]] || [[ "$pr_merged" != "null" ]]; then
        echo "✅ PR was merged"
        
        # Remove the worktree
        echo "🧹 Removing worktree: $target_branch"
        git worktree remove "$worktree_dir" 2>/dev/null || {
          echo "⚠️  Could not remove worktree automatically"
          echo "   Run: git worktree remove \"$worktree_dir\" --force"
        }

        # Delete the local branch (use -D for squash-merged branches)
        echo "🗑️  Deleting local branch: $target_branch"
        git branch -D "$target_branch" 2>/dev/null || {
          echo "⚠️  Could not delete branch automatically"
          echo "   Branch may not exist locally or may be checked out elsewhere"
        }

        echo "✅ Worktree and branch cleanup complete!"
      else
        echo "⚠️  PR is not merged (state: $pr_state)"
        echo "   Please merge the PR first, then run gwt-done again"
        echo "   To force cleanup: git worktree remove \"$worktree_dir\" --force"
        exit 1
      fi
    '';

    # Worktree cleanup
    gwt-clean = ''
      echo "Cleaning up stale worktrees..."
      git worktree prune -v
      echo "Removing merged worktree branches..."
      for wt in $(git worktree list --porcelain | grep "^worktree" | cut -d" " -f2); do
        if [ "$wt" != "$(pwd)" ]; then
          branch=$(basename "$wt")
          if git merge-base --is-ancestor "$branch" main 2>/dev/null; then
            echo "Removing merged worktree: $wt ($branch)"
            git worktree remove "$wt" 2>/dev/null || echo "Manual cleanup needed for $wt"
          fi
        fi
      done
    '';
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
      fetch.prune = true;
      fetch.pruneTags = true;
      init.defaultBranch = "main";
      init.templateDir = "${config.home.homeDirectory}/.config/git/templates";
      merge.ff = "only";
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

      if ! rg -q '^(feat|fix|docs|style|refactor|perf|test|chore|build|ci)(\(.+\))?: .+' <<< "$msg"; then
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

  home.file.".local/bin/gwt-new" = {
    text = ''
      #!/usr/bin/env bash

      set -euo pipefail

      usage() {
        echo "Usage: gwt-new <issue-number> [issue-number...] | gwt-new <branch-name>"
        echo ""
        echo "Examples:"
        echo "  gwt-new 123                    # Single issue"
        echo "  gwt-new 123 124 125           # Multiple issues (with analysis)"
        echo "  gwt-new custom-branch-name     # Custom branch name"
        exit 1
      }

      sanitize_title() {
        echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g'
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
        
        # Get the project name from the git repo
        local repo_url=$(git config --get remote.origin.url)
        local project_name=$(basename -s .git "$repo_url")
        
        # Use the standard worktree location
        local worktree_base="$HOME/dev/worktrees/$project_name"
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
        echo ""
        echo "To switch: cd $folder_path"
      }

      main() {
        if [ $# -eq 0 ]; then
          usage
        fi

        # Check if we're in a git repository
        if ! git rev-parse --git-dir >/dev/null 2>&1; then
          echo "Error: Not in a git repository" >&2
          exit 1
        fi

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

          create_worktree "$suggested_name"

        else
          # Custom branch name provided
          local branch_name=$1
          create_worktree "$branch_name"
        fi
      }

      main "$@"
    '';
    executable = true;
  };
}
