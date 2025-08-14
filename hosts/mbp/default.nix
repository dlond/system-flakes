{
  config,
  pkgs,
  lib,
  username,
  ...
}: let
  shared = import ../../lib/shared.nix {
    inherit pkgs;
    lib = pkgs.lib;
  };
in {
  environment.systemPackages =
    shared.sharedCliTools
    ++ [pkgs.raycast];

  nix.settings.experimental-features = "nix-command flakes";

  system = {
    primaryUser = username;
    stateVersion = 6;
    defaults = {
      dock = {
        autohide = true;
        show-recents = false;
      };
      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = false;
        FXRemoveOldTrashItems = true;
        FXPreferredViewStyle = "clmv";
        NewWindowTarget = "Home";
      };
    };
    # activationScripts.manageTmux.text = ''
    #   if command -v tmuxp >/dev/null && pgrep tmux >/dev/null; then
    #     echo "📦 Freezing tmux state..."
    #     tmuxp freeze > "$HOME/.tmuxp/last-session.yaml" || echo "⚠️ Failed to freeze tmux layout"
    #     echo "🛑 Killing tmux server..."
    #     tmux kill-server
    #   fi
    #
    #   if [ -f "$HOME/.tmuxp/last-session.yaml" ]; then
    #     echo "🔁 Restoring tmux layout..."
    #     tmuxp load "$HOME/.tmuxp/last-session.yaml" || echo "⚠️ Failed to restore tmux layout"
    #   fi
    # '';
  };

  security.pam.services.sudo_local.touchIdAuth = true;
  fonts.packages = [pkgs.nerd-fonts.jetbrains-mono];

  nix-homebrew = {
    enable = true;
    user = username;
  };

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };
    taps = [];
    brews = [
      "mas"
      "ollama"
    ];
    casks = [
      "1password"
      "1password-cli"
      "anythingllm"
      "claude"
      "claude-code"
      "ghostty"
      "messenger"
      "mullvad-vpn"
      "steam"
      "tor-browser"
      "vlc"
      "whatsapp"
    ];
  };
}
