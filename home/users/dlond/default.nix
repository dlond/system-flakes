{
  config,
  pkgs,
  lib,
  ...
}: {
  home = {
    stateVersion = "25.05";
    username = "dlond";
    homeDirectory =
      if pkgs.stdenv.isDarwin
      then "/Users/dlond"
      else "/home/dlond";
  };

  home.packages = [ pkgs.home-manager ];

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

  home.activation = lib.optionalAttrs pkgs.stdenv.isDarwin {
    pythonBaseEnv = config.lib.dag.entryAfter ["writeBoundary"] ''
      PY_BASE_ENV="${config.home.homeDirectory}/.local/share/python/venvs/base"

      if [ ! -d "$PY_BASE_ENV" ]; then
        $DRY_RUN_CMD ${pkgs.uv}/bin/uv venv "$PY_BASE_ENV"
      fi

      $DRY_RUN_CMD ${pkgs.uv}/bin/uv pip install --python "$PY_BASE_ENV/bin/python" \
        basedpyright ruff debugpy
    '';

    opamDefaultSwitch = config.lib.dag.entryAfter ["writeBoundary"] ''
      OPAM_HOME="${config.home.homeDirectory}/.opam"

      if [ ! -d "$OPAM_HOME" ]; then
        PATH="/usr/bin:/bin:${lib.makeBinPath (with pkgs; [
        git
        gnumake
        darwin.cctools
      ])}"

        $DRY_RUN_CMD ${pkgs.opam}/bin/opam init \
          --disable-sandboxing \
          -y

        $DRY_RUN_CMD eval "$(${pkgs.opam}/bin/opam env --switch=default --set-switch)"
        $DRY_RUN_CMD ${pkgs.opam}/bin/opam install --switch=default -y \
          ocaml-lsp-server odoc ocamlformat utop
      fi
    '';
  };

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
