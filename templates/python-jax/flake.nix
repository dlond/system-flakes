{
  description = "Python + JAX ML environment with LaTeX for quantitative research";

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

      # Import packages from system-flakes
      packages = import "${system-flakes}/lib/packages.nix" {
        inherit pkgs;
        pythonVersion = "3.12"; # Use Python 3.12 for JAX compatibility
      };

      # LaTeX distribution
      texlive = pkgs.texlive.combine {
        inherit
          (pkgs.texlive)
          scheme-medium
          latexmk
          amsmath
          mathtools
          algorithm2e
          algorithmicx
          listings
          pgfplots
          tikz-cd
          quantikz
          physics
          siunitx
          biblatex
          biber
          ;
      };
    in {
      devShells.default = pkgs.mkShell {
        buildInputs =
          # Python tools from system-flakes
          packages.python.packages {
            pythonVersion = "3.12";
            withJupyter = true;
          }
          # LaTeX support
          ++ [texlive]
          # BLAS/LAPACK for numerical computing
          ++ (with pkgs; [blas lapack])
          # Core development tools from system-flakes
          ++ packages.core.essential
          ++ packages.core.search
          ++ packages.core.utils
          # System monitoring
          ++ [pkgs.htop];

        shellHook = ''
          echo "🧮 Python + JAX ML Environment"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "Python: $(python --version)"
          echo "LaTeX: $(pdflatex --version | head -n 1)"
          echo "Package manager: uv"
          echo ""
          echo "Quick start:"
          echo "  • uv init                  - Initialize new project"
          echo "  • uv pip install -r requirements.txt"
          echo "  • uv pip install jupyterlab"
          echo "  • uv run jupyter lab       - Start Jupyter"
          echo "  • pdflatex paper.tex       - Compile LaTeX"
          echo ""
          echo "JAX installation:"
          echo "  • uv pip install jax jaxlib"
          echo "  • uv pip install optax flax equinox"
          echo ""
          echo "System tools included:"
          echo "  • basedpyright - Python LSP"
          echo "  • ruff - Python linter/formatter"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

          # Set JAX to use CPU by default (for development)
          export JAX_PLATFORM_NAME=cpu

          # Enable JAX 64-bit mode for financial calculations
          export JAX_ENABLE_X64=True

          if [ ! -f "pyproject.toml" ] && [ ! -f "requirements.txt" ]; then
            echo ""
            echo "💡 No project found. Initialize with:"
            echo "   uv init jax_ml_project"
            echo "   OR"
            echo "   cp requirements.txt from template"
          fi
        '';

        # Environment variables for numerical libraries
        OPENBLAS_NUM_THREADS = "1";
        OMP_NUM_THREADS = "1";
        MKL_NUM_THREADS = "1";
      };
    });
}
