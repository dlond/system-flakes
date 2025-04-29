{ pkgs, lib, config, ... }:

lib.mkIf pkgs.stdenv.isDarwin {
  programs.git.signing.signer = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";

  programs.zsh.shellAliases.clip = "pbcopy";
}
