{
  config,
  pkgs,
  lib,
  nvim-config,
  ...
}: let
  cfg = config.programs.neovim-cfg;
  packages = import ../../lib/packages.nix {inherit pkgs;};
in {
  options.programs.neovim-cfg = {
    enable = lib.mkEnableOption "Neovim";
    withCopilot = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable GitHub Copilot plugin.";
    };
    withDebugger = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable DAP debugger support";
    };
    withTrainingMode = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable vim training mode to build better navigation habits.";
    };
    withMolten = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Molten for Jupyter notebook support in Neovim.";
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
      withPython3 = true;
      withNodeJs = true;
      extraPackages =
        packages.neovim.packages
        ++ lib.optionals cfg.withDebugger packages.debuggers.all
        ++ cfg.extraLSPs;
      extraLuaPackages = ps:
        with ps; [
          magick
        ];
      extraPython3Packages = packages.neovim.pythonPackages;
    };

    home.file = {
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
          vim.g.python3_host_prog = '${packages.pythonWithEssentials}/bin/python3'
          
          vim.g.copilot_enabled = ${
            if cfg.withCopilot
            then "true"
            else "false"
          }
          vim.g.debugger_enabled = ${
            if cfg.withDebugger
            then "true"
            else "false"
          }
          vim.g.training_mode_enabled = ${
            if cfg.withTrainingMode
            then "true"
            else "false"
          }
          vim.g.molten_enabled = ${
            if cfg.withMolten
            then "true"
            else "false"
          }
        '';
      };
    };

    home.sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    home.shellAliases = {
      vim = "nvim";
      ndiff = "nvim -d";
    };
  };
}
