{
  config,
  pkgs,
  lib,
  nvim-config,
  ...
}: let
  cfg = config.programs.neovim-cfg;
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
    extraLSPs = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Additional LSP servers to install";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      vimAlias = true;
      withPython3 = true;
      withNodeJs = true;
      extraPackages = with pkgs;
        [
          # LSP servers
          clang-tools
          pyright
          ruff
          nixd
          texlab
          cmake-language-server
          bash-language-server
          lua-language-server

          # Formatters
          stylua
          alejandra
          black
          shfmt
          cmake-format

          # Essential tools
          ripgrep
          fd
          gnumake
          gcc
        ]
        ++ lib.optionals cfg.withDebugger [
          lldb
          python3Packages.debugpy
        ]
        ++ cfg.extraLSPs;
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
