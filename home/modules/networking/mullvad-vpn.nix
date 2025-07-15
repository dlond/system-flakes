{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.modules.networking.mullvadVpn;
  wgConfPath = "${config.home.homeDirectory}/.local/state/wireguard/wg-mullvad.conf";
  wgPrivateKeyPath = "${config.home.homeDirectory}/.secrets/wireguard/private-key";
  writeConfScript = pkgs.writeShellApplication {
    name = "write-wg-mullvad-conf";
    runtimeInputs = [pkgs.coreutils pkgs.gnugrep];
    text = ''
      set -euo pipefail

      umask 077

      wgConfPath="${wgConfPath}"
      wgPrivateKeyPath="${wgPrivateKeyPath}"
      mkdir -p "$(dirname "$wgConfPath")"

      echo "[+] Reading WireGuard private key from ${wgPrivateKeyPath}"
      PRIVATE_KEY=$(< "$wgPrivateKeyPath")

      echo "[+] Writing WireGuard conf to ${wgConfPath} atomically"
      tempfile=$(mktemp "${wgConfPath}.tmp.XXXXXX")
      chmod 600 "$tempfile"
      cat <<EOF > "$tempfile"
[Interface]
# Device: Liked Cat
PrivateKey = $PRIVATE_KEY
Address = 10.64.4.101/32,fc00:bbbb:bbbb:bb01::1:464/128
DNS = 100.64.0.63

[Peer]
PublicKey = BOEOP01bcND1a0zvmOxRHPB/ObgjgPIzBJE5wbm7B0M=
AllowedIPs = 0.0.0.0/0,::0/0
Endpoint = 103.75.11.50:51820
EOF

      mv "$tempfile" "$wgConfPath"
    '';
  };
in {
  options.home.modules.networking.mullvadVpn = {
    enable = lib.mkEnableOption "Enable user-level Mullvad VPN wiring and auto-connect.";
  };

  config = lib.mkIf cfg.enable {

    home.activation.makeWgMullvadConf = lib.hm.dag.entryAfter ["ensureSecretsDir"] ''
      echo "[+] Running activation script: writing wg-mullvad.conf"
      ${writeConfScript}/bin/write-wg-mullvad-conf
    '';

    launchd.agents.mullvad-vpn = {
      enable = true;
      config = {
        Label = "net.dlond.mullvad-vpn";
        ProgramArguments = [
          "${pkgs.wireguard-tools}/bin/wg-quick"
          "up"
          "${wgConfPath}"
        ];
        RunAtLoad = true;
        StandardOutPath = "/tmp/mullvad-vpn.out.log";
        StandardErrorPath = "/tmp/mullvad-vpn.err.log";
      };
    };

    launchd.agents.mullvad-vpn-down = {
      enable = true;
      config = {
        Label = "net.dlond.mullvad-vpn-down";
        ProgramArguments = [
          "${pkgs.wireguard-tools}/bin/wg-quick"
          "down"
          "${wgConfPath}"
        ];
        RunAtLoad = false;
        KeepAlive = false;
        # Run at logout/shutdown only
        LimitLoadToSessionType = ["Aqua"];
        # Triggers on session end
        ExitTimeOut = 5;
        StandardOutPath = "/tmp/mullvad-vpn.down.out.log";
        StandardErrorPath = "/tmp/mullvad-vpn.down.err.log";
      };
    };
  };
}
