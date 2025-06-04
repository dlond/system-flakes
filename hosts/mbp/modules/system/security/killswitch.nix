{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.modules.system.security.killswitch;
in {
  options.modules.system.security.killswitch = {
    enable = lib.mkEnableOption "Enable PF-based kill switch";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      wireguard-tools
      boringtun
    ];

    system.activationScripts.pfKillSwitch = {
      text = ''
        echo "[+] Writing safe PF kill switch rules to /etc/pf.killswitch.conf"
        cat <<EOF | sudo tee /etc/pf.killswitch.conf > /dev/null
block all
pass out on lo0 keep state
pass out on wg0 keep state

EOF
      '';
    };

    launchd.daemons.vpn-guard = {
      enable = true;
      config = {
        Label = "net.dlond.vpn-guard";
        ProgramArguments = [
          "${pkgs.bash}/bin/bash"
          "-c"
          ''
            /usr/sbin/ipconfig waitall
            /sbin/pfctl -E
            /sbin/pfctl -f /etc/pf.killswitch.conf
          ''
        ];
        RunAtLoad = true;
        StandardOutPath = "/tmp/vpn-guard.out.log";
        StandardErrorPath = "/tmp/vpn-guard.err.log";
      };
    };
  };
}
