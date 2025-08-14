{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.fzf;
  clip =
    if pkgs.stdenv.isDarwin
    then "pbcopy"
    else "xclip -selection clipboard";
in {
  options.my.fzf = {
    navBindings = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "ctrl-n:down" # next item
        "ctrl-p:up" # previous item
        "tab:down" # next item
      ];
      description = ''
        My fzf navigation bindings used by both fzf and fzf-tab.
        Take care accommodating both zstyle and FZF_DEFAULT_OPTS.
      '';
    };

    actionBindings = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "ctrl-e:execute-silent(echo {+} | ${clip})+abort" # copy selection(s) to clipboard
        "ctrl-w:become(nvim {+})" # open in neovim
        "ctrl-y:accept" # accept selection(s)
        "enter:accept" # accept selection(s)
        "shift-tab:toggle+down" # toggle, then move
      ];
      description = ''
        My fzf action bindings used by both fzf and fzf-tab.
        Take care accommodating both zstyle and FZF_DEFAULT_OPTS.
      '';
    };

    bindings = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      description = "Comma-joined bindings for --bind / fzf-tab.";
    };

    # One preview "core" that expects T=path to be set by the caller
    previewCore = lib.mkOption {
      type = lib.types.str;
      default = ''
        TARGET="$1"
        if [ -d "$TARGET" ]; then
          if command -v eza >/dev/null 2>&1; then
            eza -1 --color --group-directories-first -- "$TARGET"
          else
            command ls -1 -- "$TARGET"
          fi
        else
          if command -v bat >/dev/null 2>&1; then
            bat --style=numbers --color=always -- "$TARGET"
          else
            sed -n "1,200p" -- "$TARGET"
          fi
        fi
      '';
      description = "Shared preview body; expects path as first argument.";
    };

    # Per-caller perview strings (read-only)
    previewFzf = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      description = "Preview command for plain fzf.";
    };

    previewTab = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      description = "Preview comand for fzf-tab (uses $realpath).";
    };
  };

  config.my.fzf = {
    bindings = lib.concatStringsSep "," (cfg.navBindings ++ cfg.actionBindings);

    # fzf: {} gets passed as $1 to the shell command  
    previewFzf = "sh -c " + (lib.escapeShellArg ("(" + cfg.previewCore + ")")) + " _ {}";

    # fzf-tab: $realpath is already set by fzf-tab  
    previewTab = "sh -c " + (lib.escapeShellArg ("(" + cfg.previewCore + ")")) + " _ $realpath";
  };
}
