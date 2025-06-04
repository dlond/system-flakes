{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.modules.networking.mullvadVpn;
  wgConfDir = "${config.xdg.configHome}/wireguard/";
  wgConfPath = "${wgConfDir}/wg-mullvad.conf";
in {
  options.home.modules.networking.mullvadVpn = {
    enable = lib.mkEnableOption "Enable user-level Mullvad VPN wiring and auto-connect.";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      wireguard-tools
    ];

    home.activation.makeConf = lib.hm.dag.entryAfter ["writeBoundary"] ''
      echo "[+] Fetching private key from 1Password..."
      PRIVATE_KEY=$(/opt/homebrew/bin/op read "op://Personal/Wireguard-Mullvad/private-key")

      echo "[+] Writing WireGuard config"
      mkdir -p "${wgConfDir}"
      chmod 700 "${wgConfDir}"
      touch "${wgConfPath}"
      chmod 600 "${wgConfPath}";
      cat <<EOF > ${wgConfPath}
[Interface]
PrivateKey = $PRIVATE_KEY
Address = 10.75.178.189/32,fc00:bbbb:bbbb:bb01::c:b2bc/128
DNS = 100.64.0.55

[Peer]
PublicKey = BOEOP01bcND1a0zvmOxRHPB/ObgjgPIzBJE5wbm7B0M=
AllowedIPs = 0.0.0.0/0,::0/0
Endpoint = 103.75.11.50:51820
EOF

      echo "[+] Bringing up Mullvad tunnel ..."
      exec ${pkgs.wireguard-tools}/bin/wg-quick up ${wgConfPath}
    '';

    launchd.agents.mullvad-vpn = {
      enable = true;
      config = {
        Label = "net.dlond.mullvad-vpn";
        ProgramArguments = [
          "${pkgs.bash}/bin/bash"
          "-c"
          "${pkgs.wireguard-tools}/bin/wg-quick up ${wgConfPath}"
        ];
        RunAtLoad = true;
        StandardOutPath = "/tmp/mullvad-vpn.out.log";
        StandardErrorPath = "/tmp/mullvad-vpn.err.log";
      };
    };
  };
}
