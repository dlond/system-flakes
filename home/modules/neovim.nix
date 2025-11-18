{
  config,
  lib,
  nvim-config,
  packages,
  ...
}: let
  cfg = config.programs.neovim-cfg;
in {
  options.programs.neovim-cfg = {
    enable = lib.mkEnableOption "Neovim";
    withCopilot = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable copilot suggestions.";
    };
    withTrainingMode = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable vim training mode to build better navigation habits.";
    };
    extraLSPs = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Additional LSP servers to install";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      vimAlias = true;
      vimdiffAlias = true;
      extraPackages =
        cfg.extraLSPs;
      extraLuaPackages = ps:
        with ps; [
          magick
        ];
    };

    home = {
      file = {
        ".config/nvim/init.lua" = {
          source = nvim-config + "/init.lua";
        };
        ".config/nvim/lua" = {
          source = nvim-config + "/lua";
          recursive = true;
        };
        ".config/nvim/.stylua.toml" = {
          source = nvim-config + "/.stylua.toml";
        };
        ".config/nvim/doc" = {
          source = nvim-config + "/doc";
          recursive = true;
        };
        ".config/nvim/README.md" = {
          source = nvim-config + "/README.md";
        };
        ".config/nvim/lua/nix-settings.lua" = {
          text = ''
            -- Settings controlled by Nix configuration
            -- Set Python host program to use system Python with debugging/Jupyter packages

            vim.g.copilot_enabled = ${
              if cfg.withCopilot
              then "true"
              else "false"
            }

            vim.g.training_mode_enabled = ${
              if cfg.withTrainingMode
              then "true"
              else "false"
            }
          '';
        };
      };
      sessionVariables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
      };
      shellAliases = {
        vim = "nvim";
        ndiff = "nvim -d";
      };
    };
  };
}
