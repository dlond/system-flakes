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
    ++ pythonPackages
    ++ extraPackages;

  shellHook = ''
    echo "🐍 Python Development Environment: ${projectName}"
    echo "   Python version: ${pythonVersion}"
    echo "   Package manager: uv"
    echo "   Jupyter/Molten: enabled"

    # Note: Virtual environment is managed by direnv's 'layout python'
    # The .envrc file handles venv creation and activation

    # Install base requirements if requirements.txt exists and venv is active
    if [ -n "$VIRTUAL_ENV" ] && [ -f requirements.txt ]; then
      if ! uv pip list | grep -q "^pip " 2>/dev/null; then
        echo "Installing requirements..."
        uv pip install -r requirements.txt
      fi
    fi

    # Install development tools via uv (only if in venv)
    if [ -n "$VIRTUAL_ENV" ] && ! command -v black &> /dev/null; then
      echo "Installing development tools..."
      uv pip install black ruff ipython debugpy
    fi

    # Install Molten/Jupyter dependencies (only if in venv)
    if [ -n "$VIRTUAL_ENV" ] && ! python -c "import pynvim" 2>/dev/null; then
      echo "Installing molten-nvim dependencies..."
      uv pip install pynvim jupyter-client ipykernel jupytext nbformat
      uv pip install cairosvg pnglatex plotly kaleido pyperclip
    fi

    # Register Jupyter kernel (only if in venv)
    if [ -n "$VIRTUAL_ENV" ] && ! jupyter kernelspec list 2>/dev/null | grep -q "${projectName}-kernel"; then
      echo "Registering Jupyter kernel..."
      python -m ipykernel install --user --name=${projectName}-kernel --display-name="${projectName}"
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