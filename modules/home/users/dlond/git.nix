{ config, pkgs, ... }:

{
    programs.git = {
        enable = true;
        userName = "dlond";
        userEmail = "dlond@me.com";

        signing = {
          key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKDBuv1nRNSziTjf2UuGhFk7ftnDXOuMfew5FMeINM66";
          format = "ssh";
          # OS-specific 'signer'
        };

        # Common aliases and extraConfig could be moved to common.nix
        aliases = {
          co = "checkout";
          br = "branch";
          ci = "commit";
          uci = "reset --soft HEAD~1";
          st = "status";
          unstage = "reset HEAD --";
          last = "log -1 HEAD";
        };

        extraConfig = {
          init.defaultBranch = "main";
          core.editor = "nvim";
          color.ui = true;
          push.default = "current";
        };
    };
}
