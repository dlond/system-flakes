{
  pkgs,
  projectName ? "python-dev",
  # Version overrides
  pythonVersion ? "3.11",  # "3.9", "3.10", "3.11", "3.12", "3.13", "3.14"
  # Extra packages
  extraPackages ? [],
  extraPythonPackages ? (ps: []),
}: let
  packages = import ../lib/packages.nix {
    inherit pkgs pythonVersion;
  };

  # Get Python package using string concatenation like cpp.nix
  pythonPkg =
    if pythonVersion == "3.9" then pkgs.python39
    else if pythonVersion == "3.10" then pkgs.python310
    else if pythonVersion == "3.11" then pkgs.python311
    else if pythonVersion == "3.12" then pkgs.python312
    else if pythonVersion == "3.13" then pkgs.python313
    else if pythonVersion == "3.14" then pkgs.python314
    else throw "Unsupported Python version: ${pythonVersion}";

  # Get Python packages with our configuration (always with Jupyter now)
  pythonPackages = packages.python.packages {
    inherit pythonVersion;
    withJupyter = true;
  };

in pkgs.mkShell {
  name = "${projectName}-shell";

  buildInputs =
    packages.core.essential
    ++ packages.core.search
    ++ packages.core.utils
    ++ pythonPackages  # Just python, uv, basedpyright
    ++ (with pkgs; [
      # Development tools (non-Python)
      black
      ruff
      
      # System dependencies for Python packages
      # These enable pip packages to work properly
      imagemagick      # For image processing (matplotlib, pillow)
      ueberzugpp       # Terminal image rendering (for image.nvim)
      cairo            # For pycairo/cairosvg
      pkg-config       # For building Python C extensions
      gcc              # For building Python C extensions
      
      # Optional: Quarto for .qmd notebook support
      # quarto
    ])
    ++ extraPackages;

  shellHook = ''
    echo "🐍 Python Development Environment: ${projectName}"
    echo "   Python version: ${pythonVersion}"
    echo "   Package manager: uv"
    echo "   Jupyter/Molten: enabled with image support"

    # Note: Virtual environment is managed by direnv's 'layout python'
    # Development tools are provided by Nix
    
    # Register Jupyter kernel for this project
    if ! jupyter kernelspec list 2>/dev/null | grep -q "${projectName}"; then
      echo "Registering Jupyter kernel..."
      python -m ipykernel install --user --name="${projectName}" --display-name="${projectName} (Python ${pythonVersion})"
    fi

    echo ""
    echo "📦 Workflow:"
    echo "  1. Add dependencies:     echo 'pandas' >> requirements.txt"
    echo "  2. Install packages:     uv pip install -r requirements.txt"
    echo "  3. Run Python:           python"
    echo "  4. Run Jupyter:          jupyter notebook"
    echo "  5. In Neovim:            :MoltenInit ${projectName}-kernel"

    echo ""
    echo "✅ Environment ready!"
  '';

  # Export Jupyter path for molten-nvim
  JUPYTER_PATH = "$PWD/.venv/share/jupyter";
}