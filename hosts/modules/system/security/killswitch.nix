{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.modules.system.security.killswitch;
in {
  options.modules.system.security.killswitch = {
    enable = lib.mkEnableOption "PF VPN killswitch";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      wireguard-tools
      boringtun
    ];

    system.activationScripts.killswitch = {
      text = ''
        echo "[+] killswitch writing /etc/pf.killswitch.conf"
        if [ ! -f /etc/pf.killswitch.conf ]; then
          touch /etc/pf.killswitch.conf
          chown root:wheel /etc/pf.killswitch.conf
          chmod 644 /etc/pf.killswitch.conf
        fi
        
        cat <<EOF > /etc/pf.killswitch.conf
block all
pass out on lo0 keep state
pass out on wg0 keep state
EOF

      '';
      after = [ "network" ];
    };

    # networking.firewall.enable = true;

    launchd.daemons.vpn-guard = {
      script = ''
        /usr/sbin/ipconfig waitall
        /sbin/pfctl -E
        /sbin/pfctl -f /etc/pf.killswitch.conf
      '';

      serviceConfig = {
        Label = "net.dlond.vpn-guard";
        RunAtLoad = true;
        StandardOutPath = "/tmp/vpn-guard.out.log";
        StandardErrorPath = "/tmp/vpn-guard.err.log";
      };
    };
  };
}
