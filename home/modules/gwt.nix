# Git Worktree (gwt) Management System
# Unified git worktree workflow automation
{
  config,
  pkgs,
  lib,
  ...
}: {
  # Main gwt function injected into zsh
  programs.zsh = {
    initContent = lib.mkOrder 1100 ''
      # ============================================================================
      # GWT - Git Worktree Management System
      # ============================================================================

      # ----------------------------------------------------------------------------
      # Core Helper Functions
      # ----------------------------------------------------------------------------

      # Check if we're in a git repository
      __gwt_check_git_repo() {
        git rev-parse --git-dir >/dev/null 2>&1
      }

      # Generic flag parser
      # Usage: __gwt_parse_flags "$@"
      # Sets: __gwt_flags array and __gwt_args array
      # Caller must `set -- "''${__gwt_args[@]}"` after use!
      __gwt_parse_flags() {
        __gwt_flags=()
        __gwt_args=()

        while [ $# -gt 0 ]; do
          if [[ "$1" == --* ]]; then
            __gwt_flags+=("$1")
            shift
          else
            __gwt_args+=("$1")
            shift
          fi
        done
      }

      # Check if a flag was provided
      __gwt_has_flag() {
        local flag=$1
        for f in "''${__gwt_flags[@]}"; do
          [[ "$f" == "$flag" ]] && return 0
        done
        return 1
      }

      # Get the main branch name (main or master)
      __gwt_get_main_branch() {
        git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main"
      }

      # Get the project name
      __gwt_get_project_name() {
        local repo_url=$(git config --get remote.origin.url)
        basename -s .git "$repo_url"
      }

      # Get standard worktree base directory
      __gwt_get_worktree_base() {
        local project_name=$(__gwt_get_project_name)
        echo "$HOME/dev/worktrees/$project_name"
      }

      # Get the path to the main worktree
      # Args: $1 main branch name (optional, defaults to auto-detect)
      # Returns: worktree for the main branch
      __gwt_get_main_worktree() {
        local main_branch=''${1:-$(__gwt_get_main_branch)}

        # Try to find worktree with main branch
        local main_wt=$(git worktree list --porcelain | \
          rg -B2 "branch refs/heads/$main_branch" | \
          rg "^worktree" | \
          cut -d" " -f2 | \
          head -1)

        if [ -n "$main_wt" ]; then
          echo "$main_wt"
          return 0
        fi

        dirname "$(git rev-parse --git-common-dir)"
      }

      # Check if branch exists locally
      __gwt_branch_exists() {
        local branch=$1
        git show-ref --verify --quiet "refs/heads/$branch"
      }

      # Check if worktree exists for branch
      __gwt_worktree_exists() {
        local branch=$1
        git worktree list --porcelain | rg -q "branch refs/heads/$branch"
      }

      # Check if a worktree has uncommitted changes
      # Args: $1 = worktree (optional, defaults to current)
      # Returns: 0 if clean, 1 if dirty
      __gwt_is_worktree_clean() {
        local worktree=''${1:-.}

        git -C "$worktree" diff --quiet && git -C "$worktree" diff --staged --quiet
      }

      # Validate worktree is clean, error and exit if not
      # Args:
      #   $1 = worktreee
      #   $2 = branch name (for error messages)
      # Returns: 0 if clean, 1 if dirty (with error message)
      __gwt_require_clean_worktree() {
        local worktree=$1
        local branch=$2

        if ! __gwt_is_worktree_clean "$worktree"; then
          __gwt_print_warning "You have uncommitted changes in $branch"
          git -C "$worktree" status --short
          echo ""
          echo "Unable to proceed with uncommitted changes."
          echo "Please commit or stash your changes first:"
          echo "  cd $worktree"
          echo "  git commit -am 'your message'"
          echo "  # or"
          echo "  git stash"
          return 1
        fi

        return 0
      }


      # Build worktree list for fzf selection
      # Args:
      #   $1 = filter: "worktree" | "branch" | ""
      #   $2 = reference: (worktree or branch name)
      __gwt_build_worktree_list() {
        local exclude_worktree=""
        local exclude_branch=""

        if [ $# -eq 2 ]; then
          local filter=$1
          local reference=$2

          case "$filter" in
            worktree)
              exclude_worktree="$reference"
              ;;
            branch)
              exclude_branch="$reference"
          esac
        fi

        git worktree list --porcelain | awk -v x_br="$exclude_branch" -v x_wt="$exclude_worktree" '
          /^worktree / { worktree=$2 }
          /^branch / {
            branch=$2
            gsub("refs/heads/", "", branch)
            if (branch == "") branch="(detached)"
            if (worktree != x_wt && branch != x_br)
              printf "%s\t%s\n", worktree, branch
          }'
      }

      # Interactive fzf worktree selector with auto-select for single option
      # Args:
      #   $1 = worktree list (from __gwt_build_worktree_list)
      #   $2 = header text
      #   $3 = prompt text
      #   $4 = preview command template
      #   $5 = show_info_on_auto (optional: true/false, default: false)
      # Returns: tab-separated "path\tbranch" on stdout
      __gwt_select_worktree_fzf() {
        local worktree_list=$1
        local header=$2
        local prompt=$3
        local preview=$4
        local show_info_on_auto=''${5:-false}


        # Check if list is empty
        if [ -z "$worktree_list" ]; then
          return 1
        fi

        # Count worktrees
        local count=$(printf "%s\n" "$worktree_list" | wc -l)

        # Auto-select if only one
        if (( count == 1 )); then
          if [ "$show_info_on_auto" = true ]; then
            local branch=$(echo "$worktree_list" | cut -f2)
            __gwt_print_info "Only one other worktree found: $branch"
          fi
          echo "$worktree_list"
          return 0
        fi

        # Interactive selection
        echo "$worktree_list" | fzf \
          --header="$header" \
          --preview="$preview" \
          --preview-window="right:50%:wrap" \
          --delimiter=$'\t' \
          --with-nth=2 \
          --prompt="$prompt"
      }

      # Resolve user input to a branch name
      # Returns the branch name or empty if not found
      __gwt_resolve_to_branch() {
        local input=$1
        local resolved_branch=""

        # Case 1: Issue number
        if [[ "$input" =~ ^[0-9]+$ ]]; then
          resolved_branch=$(git worktree list --porcelain | rg "^branch" | cut -d" " -f2 | rg "[-/]$input([-/]|$)" | sed 's|^refs/heads/||' | head -1)
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
          resolved_branch=$(git rev-parse --abbrev-ref "$input" 2>/dev/null)
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

      # Get worktree for a branch
      __gwt_get_worktree() {
        local branch=$1
        git worktree list --porcelain | rg -B2 "branch refs/heads/$branch$" | rg "^worktree" | cut -d" " -f2
      }

      # Get worktree from user input
      __gwt_resolve_to_worktree() {
        local input=$1
        local branch=$(__gwt_resolve_to_branch "$input")

        if [ -z "$branch" ]; then
          return 1
        fi

        local worktree=$(__gwt_get_worktree "$branch")
        if [ -n "$worktree" ]; then
          echo "$worktree"
          return 0
        fi

        return 1
      }

      # Extract issue numbers from branch name
      __gwt_extract_issue_numbers() {
        local branch=$1
        echo "$branch" | rg -o "[0-9]+" | tr "\n" " " | sed "s/ $//"
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
          info=$(__gwt_fetch_issue_info "$issue")

          if [ $? -ne 0 ]; then
            # Failed to fetch, use fallback with issue number
            echo "  #$issue: (failed to fetch)" >&2
            titles+=("issue-$issue")
          else
            local title
            title=$(printf '%s\n' "$info" | jq -r '.title')
            titles+=("$title")

            local labels
            labels=$(printf '%s\n' "$info" | jq -r '.labels[].name' | tr '\n' ' ')
            labels_all+=("$labels")

            echo "  #$issue: $title" >&2
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
        # Check if we're in a git repository
        __gwt_check_git_repo || return 1

        __gwt_parse_flags "$@"
        set -- "''${__gwt_args[@]}"

        local stay_in_cwd=false
        __gwt_has_flag "--cwd" && stay_in_cwd=true

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

        local branch
        local issue_numbers=()

        # Check if first argument is a number (issue) or string (custom branch)
        if [[ "$1" =~ ^[0-9]+$ ]]; then
          # Issue number(s) provided
          while [[ "$1" =~ ^[0-9]+$ ]]; do
            issue_numbers+=("$1")
            shift
          done

          # Analyze issues and suggest branch name
          branch=$(__gwt_analyze_issues "''${issue_numbers[@]}")

          # Check if branch name was generated
          if [ -z "$branch" ]; then
            echo "❌ Failed to generate branch name suggestion" >&2
            echo -n "Enter custom branch name: "
            read branch
          else
            echo ""
            echo "💡 Suggested branch name: $branch"
            echo ""
            echo -n "Use this name? (y/n/edit): "
            read response

            case "$response" in
              y|Y|yes|YES|"")
                # Use suggested name
                ;;
              n|N|no|NO)
                echo -n "Enter custom branch name: "
                read branch
                ;;
              *)
                # Allow editing the suggested name
                echo -n "Edit branch name [$branch]: "
                read new_name
                [ -n "$new_name" ] && branch="$new_name"
                ;;
            esac
          fi
        else
          # Custom branch name provided
          branch=$(__gwt_sanitize_for_branch "$1")
        fi

        local worktree_base=$(__gwt_get_worktree_base)
        local worktree="$worktree_base/$branch"

        if __gwt_worktree_exists "$branch"; then
          worktree=$(__gwt_get_worktree "$branch")
          __gwt_print_info "Worktree already exists: nothing to do"
        else
          mkdir -p "$worktree"

          echo ""
          echo "Creating worktree: $worktree with branch: $branch"
          git worktree add "$worktree" -b "$branch" || return 1

          __gwt_print_success "Worktree created successfully!"
          echo "📁 Path: $worktree"
          echo "🌿 Branch: $branch"

          # Link main .envrc if exists
          local main_envrc="$(__gwt_get_main_worktree)/.envrc"
          if [ -f "$main_envrc" ]; then
            ln -s "$main_envrc" "$worktree/.envrc"
          fi
        fi

        # Change to the new worktree unless --cwd was specified
        if [ "$stay_in_cwd" = false ]; then
          echo ""
          echo "📂 Switching to new worktree..."
          cd "$worktree"
        else
          echo ""
          echo "📍 Staying in current directory (use 'cd $worktree' to switch)"
        fi
      }

      # ----------------------------------------------------------------------------
      # Command: gwt switch
      # ----------------------------------------------------------------------------

      __gwt_cmd_switch() {
        # Check if we're in a git repository
        __gwt_check_git_repo || return 1

        if [ $# -eq 1 ]; then
          local input_branch=$(__gwt_resolve_to_branch "$1")

          if [ -z "$input_branch" ]; then
            __gwt_print_error "Could not resolve '$1' to a branch"
            echo "  Tried: issue number, PR number, branch name, reflog"
            return 1
          fi

          local worktree=$(__gwt_get_worktree "$input_branch")
          if [ -z "$worktree" ]; then
            __gwt_print_error "Branch '$input_branch' exists but has no worktree"
            echo "  Create one with: gwt new $input_branch"
            return 1
          fi

          cd "$worktree" || return 1
          __gwt_print_info "Switched to: $(basename "$worktree")"
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
        local other_wts=$(__gwt_build_worktree_list "worktree" "$current_wt")

        local selected=$(__gwt_select_worktree_fzf \
          "$other_wts" \
          "Select worktree (current: $(basename "$current_wt"))" \
          "Worktree> " \
          "echo 'Path: {1}'; echo 'Branch: {2}'; echo '---'; ls -la {1} 2>/dev/null | head -20" \
          true)

        # Navigate to selected worktree
        if [ -n "$selected" ]; then
          local worktree=$(echo "$selected" | cut -f1)
          cd "$worktree" || return 1
          __gwt_print_info "Switched to: $(basename "$worktree")"
        fi
      }

      # ----------------------------------------------------------------------------
      # Command: gwt done
      # ----------------------------------------------------------------------------

      __gwt_cmd_done() {
        # Check if we're in a git repository
        __gwt_check_git_repo || return 1

        # Check flags
        __gwt_parse_flags "$@"
        set -- "''${__gwt_args[@]}"

        local close_issues=true
        __gwt_has_flag "--no-close" && close_issues=false

        # Prepare defaults: complete current directory if not main
        local br_to_complete=$(git rev-parse --abbrev-ref HEAD)
        local wt_to_complete=$(git rev-parse --show-toplevel)

        local main_branch=$(__gwt_get_main_branch)

        if [ $# -gt 0 ]; then
          local input_branch=$(__gwt_resolve_to_branch "$1")

          if [ -z "$input_branch" ]; then
            __gwt_print_error "Could not resolve '$1' to a branch"
            echo "  Tried: issue number, PR number, branch name"
            return 1
          fi

          br_to_complete="$input_branch"
          wt_to_complete=$(__gwt_get_worktree "$input_branch")

          if [ -z "$wt_to_complete" ]; then
            __gwt_print_error "Branch '$input_branch' has no worktree"
            return 1
          fi
        elif [[ "$br_to_complete" == "$main_branch" ]]; then
          br_to_complete=""
          wt_to_complete=""

          echo "📋 Select a worktree to complete:"
          echo ""

          # Get list of non-main worktrees
          local non_main_wts=$(__gwt_build_worktree_list "branch" "$main_branch")

          if [ -z "$non_main_wts" ]; then
            __gwt_print_warning "No worktrees available to complete"
            return 1
          fi

          local selected=$(__gwt_select_worktree_fzf \
            "$non_main_wts" \
            "Select worktree to complete (ESC to cancel)" \
            "Complete worktree> " \
            # "echo 'Branch: {2}'; echo 'Path: {1}'; echo '---'; echo 'Recent commits:'; git -C {1} log --oneline -5 2>/dev/null")
            "echo 'Branch: {2}'; echo 'Path: {1}'; echo '---'; echo 'Recent commits:'; git -C {1} log --oneline -5")

          if [ -z "$selected" ]; then
            echo "Cancelled."
            return 0
          fi

          wt_to_complete=$(echo "$selected" | cut -f1)
          br_to_complete=$(echo "$selected" | cut -f2)

          echo ""
        fi

        # Now proceed with completing the worktree
        echo "🎯 Completing work on worktree"
        echo "   Branch: $br_to_complete"
        echo "   Path: $wt_to_complete"
        echo ""

        # Check for uncommitted changes
        if ! git -C "$wt_to_complete" diff --quiet || ! git -C "$wt_to_complete" diff --staged --quiet; then
          __gwt_print_warning "You have uncommitted changes in $br_to_complete"
          git -C "$wt_to_complete" status --short
          echo ""
          echo "Unable to complete worktree with uncommitted changes."
          echo "Please commit or stash your changes first:"
          echo "  cd $wt_to_complete"
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
        if __gwt_pr_exists "$br_to_complete"; then
          if __gwt_is_pr_merged "$br_to_complete"; then
            __gwt_print_success "PR is merged!"
          else
            local pr_state=$(__gwt_get_pr_state "$br_to_complete")
            __gwt_print_warning "PR is not merged (state: $pr_state)"
            echo "   Please merge the PR first, then run gwt done again"
            echo "   To force cleanup: git worktree remove \"$wt_to_complete\" --force"
            return 1
          fi
        else
          # Check if branch is merged
          if ! __gwt_is_branch_merged "$br_to_complete" "origin/$main_branch"; then
            __gwt_print_warning "No PR found and branch is not merged to origin/$main_branch"
            echo "   Create a PR with: gh pr create"
            echo "   Or merge locally first"
            return 1
          fi
          __gwt_print_info "No PR, but branch is merged to origin/$main_branch"
        fi

        if [ "$wt_to_complete" = "$PWD" ]; then
          # Find the main worktree
          local main_worktree=$(__gwt_get_main_worktree "$main_branch")

          # Switch to main worktree before removing current one
          echo ""
          __gwt_print_working "Switching to main worktree..."
          cd "$main_worktree" || return 1
        fi

        # Remove the worktree
        __gwt_print_working "Removing worktree..."
        git worktree remove "$wt_to_complete" --force || {
          __gwt_print_error "Failed to remove worktree"
          return 1
        }

        # Close related issues if requested
        local issue_numbers=$(__gwt_extract_issue_numbers "$br_to_complete")
        if [ -n "$issue_numbers" ]; then
          if [ "$close_issues" = true ]; then
            __gwt_print_working "Closing related issues: $issue_numbers"
            for issue in $issue_numbers; do
              if gh issue close "$issue" 2>/dev/null; then
                __gwt_print_success "Closed issue #$issue"
              else
                echo "   Issue #$issue is already closed or doesn't exist"
              fi
            done
          else
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
        switch, sw                  Interactive worktree switcher (fzf)
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
  };
}
