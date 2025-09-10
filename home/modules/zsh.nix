{
  config,
  lib,
  pkgs,
  shared,
  ...
}: {
  programs.zsh = {
    enable = true;
    defaultKeymap = "emacs";

    shellAliases = {
      # Better ls aliases
      ls = "eza --icons"; # Simple list with icons
      ll = "eza -la --header --git --icons"; # List ALL including hidden
      la = "eza -la --header --git --icons"; # Same as ll for muscle memory
      lh = "eza -ld .* --icons"; # List ONLY hidden files/dirs
      lt = "eza -l --header --git --icons --tree"; # Tree view with details
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
      clip = shared.clipboardCommand;
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
      # Override FZF options for history widget to prevent conflicts
      FZF_CTRL_R_OPTS = "--height=40% --layout=reverse --border --preview='echo {}' --preview-window=down:3:wrap --bind='enter:accept'";
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
        # Disable zoxide doctor warning as a safety net (though proper ordering should fix it)
        export _ZO_DOCTOR=0

      '')
      ''
        # shell options
        setopt globdots
        setopt pushd_silent

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
        zstyle ':completion:*:git-checkout:*' sort false

        # safe baseline for ALL fzf-tab popups (visuals only)
        zstyle ':fzf-tab:*' fzf-flags --height=40% --layout=reverse --border --ansi \
          --color=16 \
          --color=fg:#d0d0d0,bg:#1c1c1c,hl:#d75f5f \
          --color=fg+:#ffffff,bg+:#262626,hl+:#ff5f5f \
          --color=info:#af87ff,prompt:#5f87ff,pointer:#ffaf00 \
          --color=marker:#ffff00,spinner:#5f87ff,header:#87af5f \
          --pointer=▶ --marker=✓ --info=inline

        # limp mode for emergencies
        # zstyle ':fzf-tab:*' fzf-flags --height=40% --layout=reverse --border

        # groups activated
        zstyle ':fzf-tab:*' group
        zstyle ':fzf-tab:*' group-order 'directories' 'files' 'hidden-directories' 'hidden-files'

        # Simple fzf-tab setup
        zstyle ':fzf-tab:*' show-group full
        zstyle ':fzf-tab:*' prefix ""
        zstyle ':fzf-tab:*' single-group prefix color header

        # Full keybinds to match fzf
        zstyle ':fzf-tab:*' fzf-bindings 'ctrl-n:down' 'ctrl-p:up' 'ctrl-e:execute-silent(echo {+} | ${shared.clipboardCommand})+abort' 'ctrl-w:become(nvim {+})' 'ctrl-y:accept' 'enter:toggle'

        # Enable preview for all
        zstyle ':fzf-tab:complete:*' fzf-preview 'if [[ -d $realpath ]]; then eza $realpath; else bat $realpath; fi'

        autoload -z edit-command-line
        zle -N edit-command-line
        bindkey '^x^e' edit-command-line  # Ctrl-X Ctrl-E to edit command in editor (standard emacs binding)

        _update_dirstack_conan() {
          export MY_DIRSTACK_COUNT=$#dirstack
          if [[ -n "$DYLD_LIBRARY_PATH" ]] && [[ "$DYLD_LIBRARY_PATH" == *".conan2"* ]]; then
            export IN_CONAN_ENV="1"
          else
            unset IN_CONAN_ENV
          fi
        }

        if [[ -z "$precmd_functions" ]]; then
          precmd_functions=()
        fi
        precmd_functions+=(_update_dirstack_conan)

        # Source git worktree functions
        source "$HOME/.local/lib/gwt-functions.sh"

        # Fuzzy functions
        fkill() {
          ps aux | fzf --multi --header='[kill process]' | awk '{print $2}' | xargs -r kill -9
        }

        fe() {
          local selection
          selection=$(fd --hidden --follow --exclude .git |
            fzf --preview '[[ -d {} ]] && eza -la || bat --style=numbers --color=always --line-range :500 {}' \
              --preview-window=right:60%)

          [[ -z "$selection" ]] && return
          [[ -d "$selection" ]] && cd "$selection" || ''${EDITOR:-nvim} "$selection"
        }

        fenv() {
          env | fzf --preview 'echo {}'
        }

        # Fuzzy search aliases
        fa() {
          local selection
          selection=$(alias | \
            fzf --preview 'echo {}' \
                --preview-window=up:3:wrap \
                --header='[fuzzy alias search]')
          if [[ -n "$selection" ]]; then
            # Extract just the command part after the = sign
            local cmd=$(echo "$selection" | sed "s/^[^=]*=//; s/^'//; s/'$//")
            echo "Executing: $cmd"
            eval "$cmd"
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
