{ config, pkgs, lib, ... }:

let
  # Create a wrapper for ccusage using npx
  ccusage = pkgs.writeShellScriptBin "ccusage" ''
    ${pkgs.nodejs}/bin/npx ccusage@latest "$@"
  '';
  
  # Convenience aliases for common monitoring commands
  claudeAliases = {
    # Quick status commands
    cstatus = "ccusage blocks --live";
    cdaily = "ccusage daily --compact";
    cweekly = "ccusage weekly --compact";
    cmonthly = "ccusage monthly --compact";
    csession = "ccusage session --compact";
    
    # Detailed views with breakdown
    cblocks = "ccusage blocks --breakdown";
    ctoday = "ccusage daily --since $(date +%Y%m%d) --until $(date +%Y%m%d)";
  };
in
{
  # Install the ccusage wrapper
  home.packages = [ ccusage ];
  
  # Add aliases to zsh
  programs.zsh.shellAliases = claudeAliases;
  
  # Add statusline integration for tmux (optional)
  # This could show current usage in tmux status bar
  programs.tmux.extraConfig = lib.mkAfter ''
    # Claude usage in status bar (updates every 30 seconds)
    # Uncomment to enable:
    # set -g status-right "#[fg=yellow]#(ccusage statusline --format tmux) #[default]| %H:%M"
    # set -g status-interval 30
  '';
}