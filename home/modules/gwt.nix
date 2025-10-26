# Git Worktree (gwt) Management System
# Unified git worktree workflow automation
{
  config,
  pkgs,
  lib,
  ...
}: {
  # Main gwt function injected into zsh
  programs.zsh.initContent = lib.mkOrder 1100 ''
    # ============================================================================
    # GWT - Git Worktree Management System
    # ============================================================================

    # ----------------------------------------------------------------------------
    # Core Helper Functions
    # ----------------------------------------------------------------------------

    # Get the main branch name (main or master)
    __gwt_get_main_branch() {
      git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main"
    }

    # Check if we're in a git repository
    __gwt_check_git_repo() {
      if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo "Error: Not in a git repository" >&2
        return 1
      fi
    }

    # Get the project name from repo
    __gwt_get_project_name() {
      local repo_url=$(git config --get remote.origin.url)
      basename -s .git "$repo_url"
    }

    # Get standard worktree base directory
    __gwt_get_worktree_base() {
      local project_name=$(__gwt_get_project_name)
      echo "$HOME/dev/worktrees/$project_name"
    }

    # Check if branch exists locally
    __gwt_branch_exists() {
      local branch=$1
      git show-ref --verify --quiet "refs/heads/$branch"
    }

    # Check if worktree exists for branch
    __gwt_worktree_exists() {
      local branch=$1
      git worktree list --porcelain | grep -q "branch refs/heads/$branch"
    }

    # Resolve user input to a branch name
    # Returns the branch name or empty if not found
    __gwt_resolve_to_branch() {
      local input=$1
      local resolved_branch=""

      # Case 1: given a number, could be issue number or pr number
      if [[ "$input" =~ ^[0-9]+$ ]]; then
        resolved_branch=$(__gwt_find_branch_by_issue "$input")
        if [ -n "$resolved_branch" ]; then
          echo "$resolved_branch"
          return 0
        fi
      fi

      # Case 2: PR format (pr-123, #123, pr/123)
      if [[ "$input" =~ ^(pr-|pr/|#)?([0-9]+)$ ]]; then
        local pr_num="''${BASH_REMATCH[2]}"
        resolved_branch=$(gh pr view "$pr_num" --json headRefName -q .headRefName 2>/dev/null)
        if [ -n "$resolved_branch" ] && __gwt_branch_exists "$resolved_branch"; then
          echo "$resolved_branch"
          return 0
        fi
      fi

      # Case 3: Git reflog format (@{-1} = previous branch)
      if [[ "$input" =~ ^@\{-[0-9]+\}$ ]]; then
        resolved_branch=$(git rev-parse --abbref-ref "$input" 2>/dev/null)
        if [ -n "$resolved_branch" ] && [ "$resolved_branch" != "HEAD" ]; then
          echo "$resolved_branch"
          return 0
        fi
      fi

      # Case 4: full branch name
      if __gwt_branch_exists "$input"; then
        echo "$input"
        return 0
      fi

      # Case 5: partial branch name
      # local matches=$(git for-each-ref --format='%(refname:short)' "refs/heads/*$input*")
      # if [ -n "$matches" ]; then
      #   echo "$matches"
      #   return 0
      # fi

      return 1
    }


    # Get worktree path from user input
    __gwt_resolve_to_worktree_path() {
      local input=$1
      local branch=$(__gwt_resolve_to_branch "$input")

      if [ -z "$branch" ]; then
        return 1
      fi

      local path=$(__gwt_get_worktree_path "$branch")
      if [ -n "$path" ]; then
        echo "$path"
        return 0
      fi

      return 1
    }

    # Get worktree path for a branch
    __gwt_get_worktree_path() {
      local branch=$1
      git worktree list --porcelain | grep -B2 "branch refs/heads/$branch$" | grep "^worktree" | cut -d" " -f2
    }

    # Find branch by issue number
    __gwt_find_branch_by_issue() {
      local issue_num=$1
      git worktree list --porcelain | grep "^branch" | cut -d" " -f2 | grep -E "[-/]$issue_num([-/]|$)" | sed 's|^refs/heads/||' | head -1
    }

    # Extract issue numbers from branch name
    __gwt_extract_issue_numbers() {
      local branch=$1
      echo "$branch" | grep -oE '[0-9]+' | tr '\n' ' ' | sed 's/ $//'
    }

    # Sanitize string for branch name
    __gwt_sanitize_for_branch() {
      echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g'
    }

    # Colored output helpers
    __gwt_print_error() { echo "❌ $*" >&2; }
    __gwt_print_success() { echo "✅ $*"; }
    __gwt_print_warning() { echo "⚠️  $*"; }
    __gwt_print_info() { echo "📍 $*"; }
    __gwt_print_working() { echo "🔄 $*"; }

    # ----------------------------------------------------------------------------
    # GitHub Integration Functions
    # ----------------------------------------------------------------------------

    # Check if PR exists for branch
    __gwt_pr_exists() {
      local branch=$1
      gh pr view "$branch" --json number >/dev/null 2>&1
    }

    # Get PR state
    __gwt_get_pr_state() {
      local branch=$1
      local pr_status=$(gh pr view "$branch" --json state,mergedAt 2>/dev/null || echo '{"state":"UNKNOWN"}')
      printf '%s\n' "$pr_status" | jq -r '.state'
    }

    # Check if PR is merged
    __gwt_is_pr_merged() {
      local branch=$1
      local pr_status=$(gh pr view "$branch" --json state,mergedAt 2>/dev/null || echo '{"state":"UNKNOWN"}')
      local pr_state=$(printf '%s\n' "$pr_status" | jq -r '.state')
      local pr_merged=$(printf '%s\n' "$pr_status" | jq -r '.mergedAt')
      [[ "$pr_state" == "MERGED" ]] || [[ "$pr_merged" != "null" ]]
    }

    # Check if branch is merged (via regular merge)
    __gwt_is_branch_ancestor() {
      local branch=$1
      local target_branch=''${2:-$(__gwt_get_main_branch)}
      git merge-base --is-ancestor "$branch" "$target_branch" 2>/dev/null
    }

    # Check if branch is merged by any method
    __gwt_is_branch_merged() {
      local branch=$1
      local target_branch=''${2:-$(__gwt_get_main_branch)}

      # First check: regular merge (fast, local)
      if __gwt_is_branch_ancestor "$branch" "$target_branch"; then
        return 0
      fi

      # Second check: PR merged on GitHub (catches squash/rebase)
      if __gwt_is_pr_merged "$branch"; then
        return 0
      fi

      return 1
    }

    # Fetch issue info from GitHub
    __gwt_fetch_issue_info() {
      local issue_num=$1
      local info

      info=$(gh issue view "$issue_num" --json title,labels,body 2>/dev/null) || {
        echo "Error: Could not fetch issue #$issue_num" >&2
        return 1
      }

      # Use printf instead of echo to avoid zsh interpretation of special characters
      printf '%s\n' "$info"
    }

    # Analyze multiple issues for common themes
    __gwt_analyze_issues() {
      local issues=("$@")
      local titles=()
      local labels_all=()

      echo "Analyzing issues for compatibility..." >&2
      echo "" >&2

      # Fetch all issue data
      for issue in "''${issues[@]}"; do
        local info
        info=$(__gwt_fetch_issue_info "''$issue")

        if [ $? -ne 0 ]; then
          # Failed to fetch, use fallback with issue number
          echo "  #''$issue: (failed to fetch)" >&2
          titles+=("issue-''$issue")
        else
          local title
          title=$(printf '%s\n' "$info" | jq -r '.title')
          titles+=("$title")

          local labels
          labels=$(printf '%s\n' "$info" | jq -r '.labels[].name' | tr '\n' ' ')
          labels_all+=("$labels")

          echo "  #''$issue: $title" >&2
          [ -n "$labels" ] && echo "    Labels: $labels" >&2
        fi
      done

      echo "" >&2

      # Return suggested branch name based on analysis
      if [ ''${#issues[@]} -eq 1 ]; then
        # Single issue - use sanitized title
        local title_text="''${titles[1]}"
        local issue_num="''${issues[1]}"
        local sanitized_title
        sanitized_title=$(__gwt_sanitize_for_branch "$title_text")
        echo "''${sanitized_title}-''${issue_num}"
      else
        # Multiple issues - find common theme
        local common_component=""
        local common_type=""

        # Find most common component and type from labels
        if [ ''${#labels_all[@]} -gt 0 ]; then
          local component_labels=()
          local type_labels=()
          for labels in "''${labels_all[@]}"; do
            component_labels+=($(echo "$labels" | grep -oE '\b(frontend|backend|api|ui|auth|database)\b' || true))
            type_labels+=($(echo "$labels" | grep -oE '\b(bug|feature|enhancement|refactor)\b' || true))
          done

          if [ ''${#component_labels[@]} -gt 0 ]; then
            common_component=$(printf '%s\n' "''${component_labels[@]}" | sort | uniq -c | sort -nr | head -1 | awk '{print $2}')
          fi
          if [ ''${#type_labels[@]} -gt 0 ]; then
            common_type=$(printf '%s\n' "''${type_labels[@]}" | sort | uniq -c | sort -nr | head -1 | awk '{print $2}')
          fi
        fi

        # Build suggested name
        local suggested=""
        [ -n "$common_type" ] && suggested="''${suggested}''${common_type}-"
        [ -n "$common_component" ] && suggested="''${suggested}''${common_component}-"
        [ -z "$suggested" ] && suggested="multi-issue-"

        # Append issue numbers
        local issue_list=$(printf '%s-' "''${issues[@]}")
        suggested="''${suggested}''${issue_list%-}"

        echo "$suggested"
      fi
    }

    # ----------------------------------------------------------------------------
    # Command: gwt new
    # ----------------------------------------------------------------------------

    __gwt_cmd_new() {
      local stay_in_cwd=false
      local args=()

      # Parse flags
      while [ $# -gt 0 ]; do
        case "$1" in
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
        echo "Usage: gwt new [--cwd] <issue-number> [issue-number...] | gwt new [--cwd] <branch-name>"
        echo ""
        echo "Options:"
        echo "  --cwd    Stay in current directory (don't cd to new worktree)"
        echo ""
        echo "Examples:"
        echo "  gwt new 123                    # Single issue (cd to new worktree)"
        echo "  gwt new --cwd 123              # Single issue (stay in current dir)"
        echo "  gwt new 123 124 125            # Multiple issues (with analysis)"
        echo "  gwt new custom-branch-name     # Custom branch name"
        return 1
      fi

      # Check if we're in a git repository
      __gwt_check_git_repo || return 1

      local branch_name
      local issue_numbers=()

      # Check if first argument is a number (issue) or string (custom branch)
      if [[ "$1" =~ ^[0-9]+$ ]]; then
        # Issue number(s) provided
        while [[ "$1" =~ ^[0-9]+$ ]]; do
          issue_numbers+=("$1")
          shift
        done

        # Analyze issues and suggest branch name
        branch_name=$(__gwt_analyze_issues "''${issue_numbers[@]}")

        # Check if branch name was generated
        if [ -z "$branch_name" ]; then
          echo "❌ Failed to generate branch name suggestion" >&2
          echo -n "Enter custom branch name: "
          read branch_name
        else
          echo ""
          echo "💡 Suggested branch name: $branch_name"
          echo ""
          echo -n "Use this name? (y/n/edit): "
          read response

          case "$response" in
            y|Y|yes|YES|"")
              # Use suggested name
              ;;
            n|N|no|NO)
              echo -n "Enter custom branch name: "
              read branch_name
              ;;
            *)
              # Allow editing the suggested name
              echo -n "Edit branch name [$branch_name]: "
              read new_name
              [ -n "$new_name" ] && branch_name="$new_name"
              ;;
          esac
        fi
      else
        # Custom branch name provided
        branch_name=$(__gwt_sanitize_for_branch "$1")
      fi

      # Check if branch already exists
      if __gwt_branch_exists "$branch_name"; then
        # Check if worktree exists
        if __gwt_worktree_exists "$branch_name"; then
          local existing_path=$(__gwt_get_worktree_path "$branch_name")
          __gwt_print_warning "Worktree already exists for branch: $branch_name"
          echo "  Path: $existing_path"
          echo "  Switching to existing worktree..."
          cd "$existing_path"
          return 0
        else
          __gwt_print_error "Branch exists but no worktree: $branch_name"
          echo "  Create worktree with: git worktree add <path> $branch_name"
          return 1
        fi
      fi

      # Create the worktree
      local worktree_base=$(__gwt_get_worktree_base)
      local worktree_path="$worktree_base/$branch_name"

      # Create the worktree base directory if it doesn't exist
      mkdir -p "$worktree_base"

      echo ""
      echo "Creating worktree: $worktree_path with branch: $branch_name"
      git worktree add "$worktree_path" -b "$branch_name" || return 1

      __gwt_print_success "Worktree created successfully!"
      echo "📁 Path: $worktree_path"
      echo "🌿 Branch: $branch_name"

      # Run direnv allow if .envrc exists
      if [ -f "$worktree_path/.envrc" ]; then
        echo "🔐 Running direnv allow..."
        direnv allow "$worktree_path"
      fi

      # Change to the new worktree unless --cwd was specified
      if [ "$stay_in_cwd" = false ]; then
        echo ""
        echo "📂 Switching to new worktree..."
        cd "$worktree_path"
      else
        echo ""
        echo "📍 Staying in current directory (use 'cd $worktree_path' to switch)"
      fi
    }

    # ----------------------------------------------------------------------------
    # Command: gwt switch
    # ----------------------------------------------------------------------------

    __gwt_cmd_switch() {
      # Check if we're in a git repository
      __gwt_check_git_repo || return 1

      if [ $# -eq 1 ]; then
        local branch=$(__gwt_resolve_to_branch "$1")

        if [ -z "$branch" ]; then
          __gwt_print_error "Could not resolve '$1' to a branch"
          echo "  Tried: issue number, PR number, branch name, reflog"
          return 1
        fi

        local target_path=$(__gwt_get_worktree_path "$branch")
        if [-z "$target_path" ]; then
          __gwt_print_error "Branch '$branch' exists but has no worktree"
          echo "  Create one with: gwt new $branch"
          return 1
        fi

        cd "$target_path" || return 1
        __gwt_print_success "Switched to: $branch"
        pwd
        return 0
      elif [ $# -gt 1 ]; then
        echo "Usage: gwt switch [target]"
        echo ""
        echo "Target can be:"
        echo "  - branch name: gwt switch feature-auth-123"
        echo "  - issue number: gwt switch 123"
        echo "  - PR number: gwt switch pr-123 or gwt switch #123"
        echo "  - previous branch: gwt switch @{-1}"
        echo "  - (no args): interactive fzf selector"
        return 1
      fi

      local current_wt=$(git rev-parse --show-toplevel 2>/dev/null)

      local all_wts=$(git worktree list --porcelain | awk -v cur="$current_wt" '
        /^worktree / { path=$2 }
        /^branch / {
          branch=$2
          gsub("refs/heads/", "", branch)
          if (branch == "") branch="(detached)"
          if (path != cur)
            printf "%s\t%s\n", path, branch
        }
      ')

      if [ -z "$all_wts" ]; then
        echo "No other worktrees found."
        return 1
      fi

      local count=$(printf "%s\n" "$all_wts" | wc -l)

      if (( count == 1 )); then
        local selected=$(printf "%s\n" "$all_wts" | cut -f1)
        local branch_name=$(printf "%s\n" "$all_wts" | cut -f2)
        __gwt_print_info "Only one other worktree found: $branch_name"
      else
        local selected=$(echo "$all_wts" | fzf \
          --header="Select worktree (current: $(basename "$current_wt"))" \
          --preview="echo 'Path: {1}'; echo 'Branch: {2}'; echo '---'; ls -la {1} 2>/dev/null | head -20" \
          --preview-window=right:50%:wrap \
          --delimiter=$'\t' \
          --with-nth=2 \
          --bind='ctrl-d:reload(git worktree list --porcelain | awk "/^worktree / { path=\$2 } /^branch / { branch=\$2; gsub(\"refs/heads/\", \"\", branch); if (branch == \"\") branch=\"(detached)\"; printf \"%s\\t%s\\n\", path, branch }")' \
          --prompt="Worktree> " | cut -f1)
      fi

      # Navigate to selected worktree
      if [ -n "$selected" ]; then
        cd "$selected" || return 1
        __gwt_print_info "Switched to: $(basename "$selected")"
        pwd
      fi
    }

    # ----------------------------------------------------------------------------
    # Command: gwt done
    # ----------------------------------------------------------------------------

    __gwt_cmd_done() {
      local close_issues=true
      local args=()

      # Parse flags
      while [ $# -gt 0 ]; do
        case "$1" in
          --no-close)
            close_issues=false
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

      # Check if we're in a git repository
      __gwt_check_git_repo || return 1

      # Get current worktree info
      local worktree_dir=$(git rev-parse --show-toplevel)
      local target_branch=$(git rev-parse --abbrev-ref HEAD)
      local main_branch=$(__gwt_get_main_branch)

      if [ $# -gt 0 ]; then
        local input_branch=$(__gwt_resolve_to_branch "$1")

        if [ -z "$input_branch" ]; then
          __gwt_print_error "Could not resolve '$1' to a branch"
          echo "  Tried: issue number, PR number, branch name"
          return 1
        fi

        target_branch="$input_branch"
        worktree_dir=$(__gwt_get_worktree_path "$target_branch")

        if [ -z "$worktree_dir" ]; then
          __gwt_print_error "Branch '$target_branch' has no worktree"
          return 1
        fi
      elif [[ "$target_branch" == "$main_branch" ]]; then
        echo "📋 Select a worktree to complete:"
        echo ""

        # Get list of non-main worktrees
        local all_wts=$(git worktree list --porcelain | awk -v main="$main_branch" '
          /^worktree / { path=$2 }
          /^branch / {
            branch=$2
            gsub("refs/heads/", "", branch)
            if (branch != "" && branch != main) {
              printf "%s\t%s\n", path, branch
            }
          }
        ')

        if [ -z "$all_wts" ]; then
          __gwt_print_warning "No worktrees available to complete"
          return 1
        fi

        local selected=$(echo "$all_wts" | fzf \
          --header="Select worktree to complete (ESC to cancel)" \
          --preview="echo 'Branch: {2}'; echo 'Path: {1}'; echo '---'; echo 'Recent commits:'; git -C {1} log --oneline -5 2>/dev/null" \
          --preview-window=right:50%:wrap \
          --delimiter=$'\t' \
          --with-nth=2 \
          --prompt="Complete worktree> ")

        if [ -z "$selected" ]; then
          echo "Cancelled."
          return 0
        fi

        worktree_dir=$(echo "$selected" | cut -f1)
        target_branch=$(echo "$selected" | cut -f2)

        echo ""
      fi

      # Now proceed with completing the worktree
      echo "🎯 Completing work on worktree"
      echo "   Branch: $target_branch"
      echo "   Path: $worktree_dir"
      echo ""

      # Check for uncommitted changes
      if ! git -C "$worktree_dir" diff --quiet -- "$target_branch" || ! git -C "$worktree_dir" diff --staged --quiet -- "$target_branch"; then
        __gwt_print_warning "You have uncommitted changes in $target_branch"
        git -C "$worktree_dir" status --short
        echo ""
        echo "Unable to complete worktree with uncommitted changes."
        echo "Please commit or stash your changes first:"
        echo "  cd $worktree_dir"
        echo "  git commit -am 'your_message'"
        echo "  # or"
        echo "  git stash"
        return 1
      fi

      # Fetch latest changes from remote
      __gwt_print_working "Fetching latest changes from remote..."
      git fetch origin "''${main_branch}:refs/remotes/origin/$main_branch" || {
        __gwt_print_warning "Failed to fetch latest changes from remote"
        echo "   Continuing with local state..."
      }

      # Check if PR exists and is merged
      if __gwt_pr_exists "$target_branch"; then
        if __gwt_is_pr_merged "$target_branch"; then
          __gwt_print_success "PR is merged!"
        else
          local pr_state=$(__gwt_get_pr_state "$target_branch")
          __gwt_print_warning "PR is not merged (state: $pr_state)"
          echo "   Please merge the PR first, then run gwt done again"
          echo "   To force cleanup: git worktree remove \"$worktree_dir\" --force"
          return 1
        fi
      else
        # Check if branch is merged locally (check against remote)
        if ! __gwt_is_branch_merged "$target_branch" "origin/$main_branch"; then
          __gwt_print_warning "No PR found and branch is not merged to origin/$main_branch"
          echo "   Create a PR with: gh pr create"
          echo "   Or merge locally first"
          return 1
        fi
        __gwt_print_info "No PR, but branch is merged to origin/$main_branch"
      fi

      if [ "$worktree_dir" = "$PWD" ]; then
        # Find the main worktree
        local main_worktree=$(git worktree list --porcelain | grep -B1 "branch refs/heads/$main_branch" | grep "^worktree" | cut -d" " -f2)

        if [ -z "$main_worktree" ]; then
          # If no main worktree, use the git common dir parent
          main_worktree=$(dirname "$(git rev-parse --git-common-dir)")
        fi

        # Switch to main worktree before removing current one
        echo ""
        __gwt_print_working "Switching to main worktree..."
        cd "$main_worktree" || return 1
      fi

      # Remove the worktree
      __gwt_print_working "Removing worktree..."
      git worktree remove "$worktree_dir" --force || {
        __gwt_print_error "Failed to remove worktree"
        return 1
      }

      # Close related issues if requested
      if [ "$close_issues" = true ]; then
        local issue_numbers=$(__gwt_extract_issue_numbers "$target_branch")
        if [ -n "$issue_numbers" ]; then
          __gwt_print_working "Closing related issues: $issue_numbers"
          for issue in $issue_numbers; do
            if gh issue close "$issue" 2>/dev/null; then
              __gwt_print_success "Closed issue #$issue"
            else
              echo "   Issue #$issue is already closed or doesn't exist"
            fi
          done
        fi
      else
        local issue_numbers=$(__gwt_extract_issue_numbers "$target_branch")
        if [ -n "$issue_numbers" ]; then
          __gwt_print_info "Skipping issue closing (--no-close specified) for: $issue_numbers"
        fi
      fi

      __gwt_print_success "Worktree and branch cleanup complete!"

      # Update main branch with latest changes from remote
      __gwt_print_working "Updating $main_branch with latest changes from remote..."
      if git pull origin "$main_branch" --ff-only 2>/dev/null; then
        __gwt_print_success "$main_branch branch updated successfully"
      else
        __gwt_print_warning "Could not fast-forward $main_branch (may have local commits or conflicts)"
        echo "   Run 'git pull origin $main_branch' manually to resolve"
      fi

      # We're now safely in the main worktree
      pwd
    }

    # ----------------------------------------------------------------------------
    # Command: gwt clean
    # ----------------------------------------------------------------------------

    __gwt_cmd_clean() {
      local clean_all=false

      # Parse options
      if [[ "$1" == "--all" ]]; then
        clean_all=true
      fi

      # Check if we're in a git repository
      __gwt_check_git_repo || return 1

      echo "🧹 Cleaning up worktrees..."
      echo ""

      local main_branch=$(__gwt_get_main_branch)

      if [ "$clean_all" = true ]; then
        # Remove ALL worktrees except main
        echo "⚠️  Removing ALL worktrees except main branch!"
        echo ""
        echo -n "Are you sure? (yes/no): "
        read confirm
        if [[ "$confirm" != "yes" ]]; then
          echo "Cancelled."
          return 0
        fi

        git worktree list --porcelain | awk '
          /^worktree / { path=$2 }
          /^branch / {
            branch=$2
            gsub("refs/heads/", "", branch)
            if (branch != "" && branch != "main" && branch != "master") {
              print path
            }
          }
        ' | while read -r wt_path; do
          echo "  Removing: $wt_path"
          git worktree remove "$wt_path" --force 2>/dev/null || echo "    ⚠️  Could not remove $wt_path"
        done
      else
        # Remove worktrees for merged branches
        echo "🔍 Checking for merged worktree branches..."
        local removed_count=0

        while IFS=$'\t' read -r wt_path wt_branch; do
          # Skip the main worktree
          if [ "$wt_path" = "$(git rev-parse --show-toplevel)" ]; then
            continue
          fi

          # Check if branch is merged (any method)
          if __gwt_is_branch_merged "$wt_branch" "$main_branch"; then
            # Determine merge type for user feedback
            if __gwt_is_branch_ancestor "$wt_branch" "$main_branch"; then
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
        done < <(git worktree list --porcelain | awk '
          /^worktree / { path=$2 }
          /^branch / {
            branch=$2
            gsub("refs/heads/", "", branch)
            if (branch != "") printf "%s\t%s\n", path, branch
          }
        ')

        if [ "$removed_count" -eq 0 ]; then
          echo "✨ No merged worktrees to clean up"
        else
          echo "✅ Cleaned up $removed_count worktree(s)"
        fi
      fi

      # List remaining worktrees
      echo ""
      echo "📊 Remaining worktrees:"
      git worktree list
    }

    # ----------------------------------------------------------------------------
    # Main gwt function
    # ----------------------------------------------------------------------------

    gwt() {
      local cmd="''${1:-help}"
      shift || true

      case "$cmd" in
        new)
          __gwt_cmd_new "$@"
          ;;
        switch|sw)
          __gwt_cmd_switch "$@"
          ;;
        done)
          __gwt_cmd_done "$@"
          ;;
        clean)
          __gwt_cmd_clean "$@"
          ;;
        help|--help|-h)
          cat <<'EOF'
    Git Worktree Management (gwt)

    Usage: gwt <command> [options]

    Commands:
      new [--cwd] <issue|name>    Create new worktree from issue(s) or custom name
      switch, sw                   Interactive worktree switcher (fzf)
      done [--no-close]           Complete work on worktree (fzf selector if on main)
      clean [--all]               Clean up merged/old worktrees
      help                        Show this help

    Examples:
      gwt new 123                 Create worktree for issue #123
      gwt new 123 124 125         Analyze multiple issues, create combined worktree
      gwt new my-feature          Create worktree with custom name
      gwt switch                  Interactive switch between worktrees
      gwt done                    Finish current worktree (merge PR, close issues)
      gwt clean                   Remove merged worktrees

    Tips:
      - Use 'gwt new --cwd' to stay in current directory after creation
      - Use 'gwt done --no-close' to keep issues open after completion
      - Use 'gwt clean --all' to remove ALL non-main worktrees
    EOF
          ;;
        *)
          echo "Unknown command: $cmd"
          echo "Run 'gwt help' for usage"
          return 1
          ;;
      esac
    }
  '';
}
