{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.modules.networking.mullvad;
in {
  options.modules.networking.mullvad = {
    enable = lib.mkEnableOption "Enable Mullvad WireGuard VPN with 1Password";
    privateKeyItem = lib.mkOption {
      type = lib.types.str;
      description = "1Password item path to retrieve the private key, e.g. op://mullvad-vpn/private-key";
    };
    configFile = lib.mkOption {
      type = lib.types.lines;
      description = "Contents of the mullvad.conf (without PrivateKey)";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      wireguard-tools
      boringtun
    ];

    xdg.configFile."wireguard/mullvad.conf".text = cfg.configFile;

    home.file = {
      "bin/wg-up-mullvad.sh" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash
          set -euo pipefail

          echo "🔐 Fetching Mullvad key from 1Password..."
          PRIVATE_KEY=$(op read "op://Personal/mullvad/private-key")

          echo "Injecting private key and bringing up WireGuard tunnel..."
          export WG_QUICK_USERSPACE_IMPLEMENTATION=boringtun

          # Inject the private key dynamically
          sudo -E WG_PRIVATE_KEY="$PRIVATE_KEY" wg-quick up mullvad
        '';
      };
    };

    home.file = {
      "bin/wg-down-mullvad.sh" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash
          sudo wg-quick down mullvad
        '';
      };
    };
  };
}
