{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.modules.networking.mullvad;
  wgConfPath = "${config.xdg.configHome}/wireguard/mullvad.conf";
  keyPath = "${config.home.homeDirectory}/.secrets/wireguard/private-key";
  upScript = ''
    #!/usr/bin/env bash
    echo "[+] Reading WireGuard private key from ${keyPath}"
    PRIVATE_KEY=$(< "${keyPath}")

    echo "[+] Writing WireGuard config to ${wgConfPath}"
    mkdir -p "${config.xdg.configHome}/wireguard"
    chmod 700 "${config.xdg.configHome}/wireguard"
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

    echo "[+] Bringing up Mullvad tunnel..."
    exec ${pkgs.wireguard-tools}/bin/wg-quick up ${wgConfPath}
  '';
in {
  options.home.modules.networking.mullvad = {
    enable = lib.mkEnableOption "Enable user-level Mullvad VPN wiring and auto-connect.";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      wireguard-tools
    ];

    home.activation.fetchVpnKey = lib.hm.dag.entryAfter ["writeBoundary"] ''
      echo "[+] Creating secrets directory"
      mkdir -p "${config.home.homeDirectory}/.secrets/wireguard"
      chmod 700 "${config.home.homeDirectory}/.secrets"
      touch "${keyPath}"
      chmod 600 "${keyPath}"

      echo "[+] Fetching private key from 1Password..."
      /opt/homebrew/bin/op read "op://Personal/Wireguard-Mullvad/private-key" > "${keyPath}"
    '';

    home.activation.mkConf = lib.hm.dag.entryAfter ["writeBoundary"] ''
    echo "[+] Reading WireGuard private key from ${keyPath}"
    PRIVATE_KEY=$(< "${keyPath}")

    echo "[+] Writing WireGuard config to ${wgConfPath}"
    mkdir -p "${config.xdg.configHome}/wireguard"
    chmod 700 "${config.xdg.configHome}/wireguard"
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
      '';

    home.file.".config/wireguard/wg-up-mullvad.sh" = {
      text = upScript;
      executable = true;
    };

    launchd.agents.mullvad-vpn = {
      enable = true;
      config = {
        Label = "net.dlond.mullvad-vpn";
        ProgramArguments = [
          "${pkgs.bash}/bin/bash"
          "-c"
          "${config.xdg.configHome}/wireguard/wg-up-mullvad.sh"
        ];
        RunAtLoad = true;
        StandardOutPath = "/tmp/mullvad-vpn.out.log";
        StandardErrorPath = "/tmp/mullvad-vpn.err.log";
      };
    };
  };
}
