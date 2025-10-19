{
  config,
  pkgs,
  lib,
  ...
}: {
  # Commit message template
  home.file.".config/git/commit-template".text = ''
    # Commit Message Template
    #
    # Format: <type>: <subject>
    #
    # Types:
    #   feat:     New feature
    #   fix:      Bug fix
    #   docs:     Documentation only changes
    #   style:    Code style changes (formatting, semicolons, etc)
    #   refactor: Code change that neither fixes a bug nor adds a feature
    #   perf:     Performance improvements
    #   test:     Adding or updating tests
    #   chore:    Maintenance tasks, dependency updates
    #   build:    Build system or external dependency changes
    #   ci:       CI configuration changes
    #
    # Subject: Brief description (imperative mood, lowercase, no period)
    #
    # Body: Detailed explanation of changes (optional)
    # - Why was this change necessary?
    # - What problem does it solve?
    # - Any side effects or breaking changes?
    #
    # Footer:
    # - Reference issues: Fixes #123, Closes #456
    # - AI acknowledgment (always include):
    #
    # 🤖 Generated with Claude Code
    # Co-Authored-By: Claude <noreply@anthropic.com>
    #
    # Example:
    # --------
    # fix: correct gwt-nav command name in documentation
    #
    # Updated all references from 'wt' to 'gwt-nav' to match the actual
    # command implementation in system-flakes.
    #
    # Fixes #5
    #
    # 🤖 Generated with Claude Code
    # Co-Authored-By: Claude <noreply@anthropic.com>
  '';

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

  home.packages = with pkgs; [
    delta
    git-filter-repo
  ];

  programs.git = {
    enable = true;

    signing =
      {
        key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKDBuv1nRNSziTjf2UuGhFk7ftnDXOuMfew5FMeINM66";
        format = "ssh";
      }
      // lib.optionalAttrs pkgs.stdenv.isDarwin {
        signer = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
      };
    settings = {
      user.name = "dlond";
      user.email = "dlond@me.com";

      alias = {
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

      color.ui = true;
      commit.template = "${config.home.homeDirectory}/.config/git/commit-template";
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
        url: https://github.com/[YOUR_USERNAME]/[YOUR_REPO]/discussions
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
}
