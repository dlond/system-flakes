{ pkgs, lib, config, ... }:

lib.mkIf pkgs.stdenv.isLinux {
  programs.git.signing.signer = "<your-linux-helper>";

  programs.zsh.shellAliases.clip = "xclip -selection clipboard";
  programs.zsh.initContent = ''
    export PATH="$HOME/bin:$PATH"
  '';
}
