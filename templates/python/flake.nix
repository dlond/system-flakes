{
  description = "Python development environment with uv";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      lib = pkgs.lib;

      config = {
        name = "Python Development";

        pythonVersion = "3.14"; # Change this to use different Python version (3.10, 3.11, 3.12, 3.13, 3.14)
      };

      packages = [
        pkgs."python${lib.replaceStrings ["."] [""] config.pythonVersion}"
        pkgs.uv
      ];
    in {
      devShells.default = pkgs.mkShell {
        name = config.name;
        nativeBuildInputs = packages;
        ENV_ICON = "❄️";

        shellHook = ''
          if [ ! -d ".git" ]; then
            git init
          fi
          echo "🐍 Python development environment"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "Python version: $(python --version)"
          echo "uv version: $(uv --version)"
          echo ""

          # Create local venv
          if [ ! -d ".venv" ]; then
            echo "Creating venv for Python $(python --version)..."
            uv venv
            uv sync --all-extras
            echo ""
            echo "Install dependencies with: uv sync --all-extras"
            echo ""
          fi
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        '';
      };
    });
}
