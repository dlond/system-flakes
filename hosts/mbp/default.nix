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
  };

  security.pam.services.sudo_local.touchIdAuth = true;
  fonts.packages = [pkgs.nerd-fonts.jetbrains-mono];

  sops = {
    age.keyFile = "${config.system.primaryUserHome}/Library/Application Support/sops/age/keys.txt";

    secrets.mullvadPrivateKey = {
      sopsFile = ../../secrets/wireguard.yaml;
      key = "wireguard-mullvad-private-key";
      path = "/run/secrets/mullvad/private-key";
      owner = "root";
      group = "wheel";
      mode = "0400";
      neededForUsers = true;
    };
  };

  networking.wg-quick.interfaces."mullvad" = {
    autostart = false;
    privateKeyFile = "/run/secrets/mullvad/private-key";
    address = ["10.64.4.101/32" "fc00:bbbb:bbbb:bb01::1:464/128"];
    dns = ["100.64.0.63"];

    peers = [
      {
        publicKey = "BOEOP01bcND1a0zvmOxRHPB/ObgjgPIzBJE5wbm7B0M=";
        endpoint = "103.75.11.50:51820";
        allowedIPs = ["0.0.0.0/0" "::0/0"];
        persistentKeepalive = 25;
      }
    ];
  };

  # launchd.daemons.wg-quick-mullvad = {
  #   serviceConfig.ProgramArguments = lib.mkForce [
  #     # "${pkgs.bash}/bin/bash"
  #     "/bin/sh"
  #     "-c"
  #     "/bin/wait4path /nix/store &amp;&amp; exec ${pkgs.wireguard-tools}/bin/wg-quick up mullvad"
  #   ];
  # };

  # system.activationScripts.wgQuickUp.text = ''
  #   echo "▶️ running wgQuickUp activation script" >> /tmp/wg-debug.log
  #
  #   CONF=/private/etc/wireguard/mullvad.conf
  #   if [ ! -f "$CONF" ]; then
  #     echo "❌ config not found at $CONF" >> /tmp/wg-debug.log
  #     exit 1
  #   fi
  #
  #   if ! /run/current-system/sw/bin/wg show utun4 >/dev/null 2>&1; then
  #     echo "→ [$(date)] bringing up Mullvad" >> /tmp/wg-debug.log
  #     /run/current-system/sw/bin/wg-quick up mullvad >> /tmp/wg-debug.log 2>&1
  #   else
  #     echo "✅ WireGuard already active" >> /tmp/wg-debug.log
  #   fi
  # '';

  system.activationScripts.wgQuickUp = {
    text = ''
      echo "✅ running wgQuickUp at $(date)" >> /tmp/wg-debug.log
    '';
    enable = true;
    deps = [];
  };

  system.activationScripts.scriptOrder = lib.mkAfter ["wgQuickUp"];

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
    ];
    casks = [
      "1password"
      "1password-cli"
      "ghostty"
      "steam"
      "tor-browser"
      "vlc"
    ];
  };
}
