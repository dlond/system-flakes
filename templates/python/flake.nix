{
  description = "Python development environment with uv";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    system-flakes = {
      url = "github:dlond/system-flakes";
      # For local development: url = "path:/Users/dlond/dev/projects/system-flakes";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    system-flakes,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      # Import packages from system-flakes with custom Python version if needed
      packages = import "${system-flakes}/lib/packages.nix" {
        inherit pkgs;
        pythonVersion = "3.12"; # Change this to use different Python version (3.10, 3.11, 3.12, 3.13, 3.14)
      };

      # Python with only the essential packages for Neovim integration
      pythonEnv = packages.pythonPkg.withPackages (ps:
        with ps; [
          debugpy # For DAP debugging in Neovim
          pynvim # For Neovim Python host
          jupyter-client # For Molten/Jupyter integration
          ipykernel # For creating Python kernels
        ]);
    in {
      devShells.default = pkgs.mkShell {
        name = "python-dev";

        buildInputs = with pkgs; [
          # Python and package management
          pythonEnv
          uv # Fast Python package manager - handles all project dependencies

          # Development tools (minimal set for Neovim)
          basedpyright # LSP
          ruff # Linter and formatter
          packages.pythonPkg.pkgs.pytest # Testing framework (matches Python version)

          # Core tools from system-flakes
          packages.core.essential
          packages.core.search

          # Optional: Jupyter support for notebooks
          imagemagick
          poppler-utils
        ];

        shellHook = ''
          echo "Python development environment"
          echo "Python: $(python --version)"
          echo "uv: $(uv --version)"
          echo ""
          echo "Usage:"
          echo "  uv venv              # Create virtual environment"
          echo "  source .venv/bin/activate  # Activate venv"
          echo "  uv pip install -r requirements.txt  # Install from requirements"
          echo "  uv add <package>     # Add dependency (if using pyproject.toml)"
          echo "  uv sync              # Install dependencies from pyproject.toml"
          echo ""
          echo "All project dependencies should be managed by uv in a venv, not nix."

          # Check for virtual environment
          if [ ! -d .venv ]; then
            echo ""
            echo "No .venv found. Run 'uv venv' to create a virtual environment."
          else
            echo ""
            echo "Virtual environment found. Run 'source .venv/bin/activate' to activate."
          fi
        '';

        # Ensure uv uses project-local venv
        UV_PROJECT_ENVIRONMENT = ".venv";
      };
    });
}
