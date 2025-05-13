# { pkgs, lib, config, ... }:
{
  programs.git.signing.signer = "<your-linux-helper>";

  programs.zsh.shellAliases.clip = "xclip -selection clipboard";
  programs.zsh.initContent = ''
    export PATH="$HOME/bin:$PATH"
  '';

  xdg.configFile."direnv/direnv.toml".text = ''
    [global]
    hide_env_diff = true
  '';
}
