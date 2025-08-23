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
  nix_netrc = "/etc/nix/netrc";
in {
  environment.systemPackages =
    shared.sharedCliTools
    ++ [
      pkgs.raycast
      pkgs.pam-reattach  # For Touch ID support in tmux
    ];

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

  sops.age = {
    generateKey = true;
    keyFile = "/var/lib/sops/age/key.txt";
  };

  sops.secrets.github_netrc = {
    sopsFile = ../../secrets/github-netrc.yaml;
    path = "${nix_netrc}";
    mode = "0644";
    owner = "root";
    group = "wheel";
  };

  nix.settings = {
    netrc-file = "${nix_netrc}";
    trusted-users = ["root" "dlond"];
  };

  # Configure PAM for Touch ID with tmux support
  # The pam-reattach module moves sudo to the GUI session for Touch ID access
  environment.etc."pam.d/sudo_local".text = ''
    # Written by nix-darwin
    auth       optional       ${pkgs.pam-reattach}/lib/pam/pam_reattach.so
    auth       sufficient     pam_tid.so
  '';
  
  # This is the standard Touch ID config (kept for reference but overridden above)
  # security.pam.services.sudo_local.touchIdAuth = true;
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
