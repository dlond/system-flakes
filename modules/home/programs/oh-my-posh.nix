{ pkgs, ... }:

{
  programs.oh-my-posh = {
    enable = true;
    settings = {
      version = "latest";
      theme = "${pkgs.writeText "dlond.omp.toml" (builtins.readFile ./themes/dlond.omp.toml)}";
    };
  };
}

