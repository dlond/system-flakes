{ config, pkgs, lib, ... }:

{
  programs.git = {
    signing.signer = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
  };
}
