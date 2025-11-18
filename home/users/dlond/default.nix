{
  config,
  pkgs,
  ...
}: {
  home = {
    stateVersion = "25.05";
    username = "dlond";
    homeDirectory = "/Users/dlond";
  };

  imports = [
    ../../modules/fzf.nix
    ../../modules/git.nix
    ../../modules/gwt.nix
    # ../../modules/claude-monitoring.nix
    ../../modules/nvdev.nix
    ../../modules/tmux.nix
    ../../modules/zsh.nix
    ../../modules/neovim.nix
  ];

  # This is to force me to not use the default switch
  home.file.".opam/default/.read-only-placeholder".text = "Use local switches only";

  # Python base environment for Neovim LSP (basedpyright, ruff, debugpy)
  # Used when not in a project-specific venv
  home.activation.pythonBaseEnv = config.lib.dag.entryAfter ["writeBoundary"] ''
    BASE_ENV="${config.home.homeDirectory}/.local/share/python/venvs/base"

    $DRY_RUN_CMD ${pkgs.uv}/bin/uv venv --clear "$BASE_ENV"
    $DRY_RUN_CMD ${pkgs.uv}/bin/uv pip install --python "$BASE_ENV/bin/python" \
      basedpyright ruff debugpy
  '';

  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;
      silent = true;
      config = {
        global = {
          warn_timeout = "0";
        };
      };
      package = pkgs.direnv.overrideAttrs (oldAttrs: {
        nativeCheckInputs = builtins.filter (pkg: pkg != pkgs.fish) oldAttrs.nativeCheckInputs;
        checkPhase = ''
          runHook preCheck
          make test-go test-bash test-zsh
          runHook postCheck
        '';
      });
    };

    neovim-cfg = {
      enable = true;
      withTrainingMode = false;
      withCopilot = false;
    };
  };

  xdg = {
    configFile = {
      "ghostty/config" = {
        text = ''
          font-family = "JetBrains Mono Nerd Font"
          font-size = 13
          theme = dlond.ghostty

          working-directory = "${config.home.homeDirectory}/dev"
          window-inherit-working-directory = true
          clipboard-paste-protection = false

          macos-option-as-alt = true

          # Keybindings
          keybind = global:option+space=toggle_quick_terminal
        '';
      };
      "ghostty/themes/dlond.ghostty" = {
        source = ./themes/dlond.ghostty;
      };

      ".ocamlformat" = {
        source = ./configs/dlond.ocamlformat;
      };
    };
  };
}
