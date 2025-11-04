{
  config,
  lib,
  pkgs,
  packages,
  ...
}: {
  programs.zsh = {
    enable = true;
    defaultKeymap = "emacs";

    shellAliases = {
      # Better ls aliases
      ls = "eza --icons=always"; # Simple list with icons
      ll = "eza -la --header --git --icons=always"; # List ALL including hidden
      la = "eza -la --header --git --icons=always"; # Same as ll for muscle memory
      lh = "eza -ld .* --icons=always"; # List ONLY hidden files/dirs
      lt = "eza -l --header --git --icons=always --tree"; # Tree view with details
      tree = "eza --tree";

      # File tools
      cat = "bat";
      v = "nvim";
      ndiff = "nvim -d";

      # Safety aliases
      rm = "rm -i"; # Interactive confirmation

      # Fuzzy tools
      fh = "fc -l 1 | fzf --tac --height=50% | sed 's/^[[:space:]]*[0-9]*[[:space:]]*//' | sh";

      # Nix shortcuts
      nfc = "nix flake check";
      nfu = "nix flake update";
      nd = "nix develop";
      drs = "darwin-rebuild switch --flake .#mbp";

      # Quick navigation
      dev = "cd ~/dev";
      proj = "cd ~/dev/projects";
      wt = "cd ~/dev/worktrees";

      # Other
      firefox = "open -a \"Firefox\" --args";
      clip = packages.system.clipboardCommand;
    };

    history = {
      size = 5000;
      save = 5000;
      path = "$HOME/.zsh_history";
      extended = true;
      share = true;
      ignoreSpace = true;
      ignoreAllDups = true;
      saveNoDups = true;
      findNoDups = true;
    };

    sessionVariables = {
      EDITOR = "nvim";
      # FZF widget commands
      FZF_CTRL_T_COMMAND = "fd --type f --hidden --follow --exclude .git";
      FZF_ALT_C_COMMAND = "fd --type d --hidden --follow --exclude .git";
      FZF_CTRL_R_OPTS = "--height=40% --layout=reverse --border --preview='echo {}' --preview-window=down:3:wrap --bind='enter:accept' --bind='ctrl-e:execute(echo {} | clip)+abort' --header='[history] | Ctrl-E: copy'";
      # Common FZF bindings for all custom functions
      FZF_CUSTOM_BINDS = "--bind='ctrl-e:execute(echo {} | clip)+abort' --bind='ctrl-w:become(nvim {})'";
    };

    syntaxHighlighting = {
      enable = true;
      highlighters = ["main"];
    };

    autosuggestion.enable = true;

    plugins = [
      {
        name = "fzf-tab";
        src = pkgs.zsh-fzf-tab.src;
      }
    ];

    initContent = lib.mkMerge [
      (lib.mkBefore ''
        # Add ~/.local/bin to PATH for user scripts
        export PATH="$HOME/.local/bin:$PATH"

        # Disable zoxide doctor warning as a safety net (though proper ordering should fix it)
        export _ZO_DOCTOR=0

      '')
      ''
        # shell options
        setopt globdots
        setopt pushd_silent
        setopt IGNOREEOF  # Prevent ^D from immediately exiting, let our widget handle it

        # keybindings
        bindkey '^y' autosuggest-accept
        bindkey '^p' history-search-backward
        bindkey '^n' history-search-forward

        # completion styling
        if [[ -n "$LS_COLORS" ]]; then
          zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
        fi

        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
        zstyle ':completion:*' menu no

        # safe baseline for ALL fzf-tab popups (visuals only)
        zstyle ':fzf-tab:*' fzf-flags --height=40% --layout=reverse --border --ansi \
          --color=16 \
          --color=fg:#d0d0d0,bg:#1c1c1c,hl:#d75f5f \
          --color=fg+:#ffffff,bg+:#262626,hl+:#ff5f5f \
          --color=info:#af87ff,prompt:#5f87ff,pointer:#ffaf00 \
          --color=marker:#ffff00,spinner:#5f87ff,header:#87af5f \
          --pointer=▶ --marker=✓ --info=inline

        # groups activated
        zstyle ':fzf-tab:*' group
        zstyle ':fzf-tab:*' group-order 'directories' 'files' 'hidden-directories' 'hidden-files'

        # Simple fzf-tab setup
        zstyle ':fzf-tab:*' show-group full
        zstyle ':fzf-tab:*' prefix ""
        zstyle ':fzf-tab:*' single-group prefix color header

        # Full keybinds to match fzf
        zstyle ':fzf-tab:*' fzf-bindings \
          'ctrl-n:down' 'tab:down' \
          'ctrl-p:up' 'shift-tab:up' \
          'ctrl-y:accept' 'enter:accept' \
          'ctrl-e:execute-silent(echo {+} | clip)+abort' \
          'ctrl-w:become(nvim {+})' \
          'space:toggle' \

        zstyle ':fzf-tab:*' continuous-trigger '/'

        # Enable preview for all
        zstyle ':fzf-tab:complete:*' fzf-preview 'if [[ -d $realpath ]]; then eza $realpath; else bat $realpath; fi'

        zstyle ':fzf-tab:complete:*' popup-pad 30 0

        # Git-specific completions with previews
        zstyle ':fzf-tab:complete:git-branch:*' fzf-preview 'git log --oneline --graph --color=always $word'
        zstyle ':fzf-tab:complete:git-checkout:*' fzf-preview 'git log --oneline --graph --color=always $word'
        zstyle ':fzf-tab:complete:git-switch:*' fzf-preview 'git log --oneline --graph --color=always $word'
        zstyle ':fzf-tab:complete:git-merge:*' fzf-preview 'git log --oneline --graph --color=always $word'
        zstyle ':fzf-tab:complete:git-rebase:*' fzf-preview 'git log --oneline --graph --color=always $word'

        # For git diff, show actual diff preview
        zstyle ':fzf-tab:complete:git-diff:*' fzf-preview 'git diff --color=always $word'

        # For git add, show file diff
        zstyle ':fzf-tab:complete:git-add:*' fzf-preview 'git diff --color=always -- $realpath 2>/dev/null || bat --color=always $realpath'

        # For branch deletion, show the branch info
        zstyle ':fzf-tab:complete:git-branch:argument-rest:' fzf-preview 'git log --oneline --graph --color=always --max-count=20 $word'

        # Show recent branches first
        zstyle ':completion:*:git-checkout:*' recent-branches-first true
        zstyle ':completion:*:git-checkout:*' sort false

        # Group git results nicely
        zstyle ':fzf-tab:complete:git-*:*' group-order 'modified files' 'untracked files' 'branches' 'tags' 'commits' 'remotes'


        autoload -z edit-command-line
        zle -N edit-command-line
        bindkey '^x^e' edit-command-line  # Ctrl-X Ctrl-E to edit command in editor (standard emacs binding)

        _update_dirstack() {
          export MY_DIRSTACK_COUNT=$#dirstack
        }

        if [[ -z "$precmd_functions" ]]; then
          precmd_functions=()
        fi
        precmd_functions+=(_update_dirstack)

        # Load FZF keybindings manually (Claude Code runs zsh with ZLE off)
        if command -v fzf &> /dev/null; then
          eval "$(fzf --zsh)"
        fi

        # Make <Ctrl-D> deactivate venv if present, otherwise proceed as normal
        activate_conan() {
          source "$1"
          export CONAN_VIRTUAL_ENV="$(cd "$(dirname "$1")" && pwd)"

          deactivate() {
            [[ -f "$CONAN_VIRTUAL_ENV/deactivate_conanrun.sh" ]] && source "$CONAN_VIRTUAL_ENV/deactivate_conanrun.sh"
            unset CONAN_VIRTUAL_ENV
            unset -f deactivate
          }
        }

        smart_ctrl_d() {
          if [[ -z "$BUFFER" ]]; then
            if [[ -n "$VIRTUAL_ENV" ]] || [[ -n "$CONAN_VIRTUAL_ENV" ]]; then
              if type deactivate &>/dev/null; then
                deactivate
                local precmd
                for precmd in $precmd_functions; do
                  $precmd
                done
                zle reset-prompt
              else
                exit 0
              fi
            else
              exit 0
            fi
          else
            zle delete-char-or-list
          fi
        }

        zle -N smart_ctrl_d
        bindkey '^D' smart_ctrl_d

        # Fuzzy functions
        fkill() {
          ps aux | fzf --multi --header='[kill process] | Ctrl-E: copy PID' \
            --bind='ctrl-e:execute(echo {2} | clip)+abort' | awk '{print $2}' | xargs -r kill -9
        }

        sf() {
          local selection
          selection=$(fd --hidden --follow --exclude .git |
            fzf --preview '[[ -d {} ]] && eza -la || bat --style=numbers --color=always --line-range :500 {}' \
              --preview-window=right:60% \
              --header='[file search] | Ctrl-E: copy | Ctrl-W: nvim' \
              $FZF_CUSTOM_BINDS)

          [[ -z "$selection" ]] && return
          [[ -d "$selection" ]] && cd "$selection" || ''${EDITOR:-nvim} "$selection"
        }

        se() {
          env | fzf --preview 'echo {}' \
            --header='[env vars] | Ctrl-E: copy' \
            --bind='ctrl-e:execute(echo {} | clip)+abort'
        }

        # Fuzzy search aliases
        sa() {
          local selection
          selection=$(alias | \
            fzf --preview 'echo {}' \
                --preview-window=up:3:wrap \
                --header='[alias search] | Ctrl-E: copy' \
                --bind='ctrl-e:execute(echo {} | clip)+abort')
          if [[ -n "$selection" ]]; then
            # Extract just the command part after the = sign
            local cmd=$(echo "$selection" | sed "s/^[^=]*=//; s/^'//; s/'$//")
            echo "Executing: $cmd"
            eval "$cmd"
          fi
        }

        sk() {
          local selection
          selection=$(bindkey |
            fzf --preview 'key={1}; func={2}; echo "Key: $key\nFunction: $func"; echo "---"; case $func in
              *autosuggest*) echo "Zsh autosuggestions function" ;;
              *history*) echo "History navigation" ;;
              *fzf*) echo "FZF widget function" ;;
              *edit*) echo "Edit/modify command" ;;
              *complete*) echo "Completion function" ;;
              *) echo "Zsh widget: $func" ;;
            esac' \
                --preview-window=up:4:wrap \
                --header='[keybind search] | Ctrl-E: copy' \
                --bind='ctrl-e:execute(echo {1} {2} | clip)+abort')

          if [[ -n "$selection" ]]; then
            echo "$selection"
          fi
        }

      ''
      # Initialize zoxide at the very end
      (lib.mkOrder 2000 ''
        eval "$(${pkgs.zoxide}/bin/zoxide init zsh --cmd cd)"
      '')
    ];
  };
}
