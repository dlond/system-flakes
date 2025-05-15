{ pkgs, ... };
{
  networking.hostName = "linux";

  users.users.dlond = {
    isNormalUser = true;
    home = "/home/dlond";
    extraGroups = [ "wheel" ];
  };
}
