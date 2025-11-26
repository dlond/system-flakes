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
        pythonVersion = "3.14"; # Change this to use different Python version (3.10, 3.11, 3.12, 3.13, 3.14)
      };

      packages = [
        pkgs."python${lib.replaceStrings ["."] [""] config.pythonVersion}"
        pkgs.uv
      ];
    in {
      devShells.default = pkgs.mkShell {
        nativeBuildInputs = packages;
        ENV_ICON = "❄️";

        shellHook = ''
          # set naming project
          if [ ! -f .projectName ]; then
            NAME=''${PROJECT_NAME:-$(basename "$PWD")}
            rg -l __PROJECT_NAME__ | xargs sed -i "s/__PROJECT_NAME__/$NAME/g"
            fd  __PROJECT_NAME__ | sort -r | while read -r dir; do
            newdir="''${dir//__PROJECT_NAME__/$NAME}"
            mv "$dir" "$newdir"
            done

            echo "PROJECT_NAME: $NAME" > .projectName
          fi

          # local venv
          if [ ! -d ".venv" ]; then
            echo "🐍 No venv found. Creating ..."

            # worktrees just link venvs
            if [ -f ".git" ]; then
              MAIN_WT=$(git worktree list | awk 'NR == 1 { print $1; exit }')
              echo "   Linking venv at $MAIN_WT ..."
              ln -s "$MAIN_WT/.venv" .venv

              echo "✅ Project venv linked."
            else
              uv venv
              uv sync --all-extras

              echo "✅ Project venv created."
            fi
          fi
          echo "🐍 Python development environment"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "Python version: $(python --version)"
          echo "uv version: $(uv --version)"
          echo ""
        '';
      };
    });
}
