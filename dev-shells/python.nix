{
  pkgs,
  pythonVersion ? "3.11",  # "3.9", "3.10", "3.11", "3.12", "3.13"
  withJupyter ? false,
  withMolten ? false,
  extraPackages ? [],
  extraPythonPackages ? (ps: []),
  projectName ? "python-dev",
}: let
  # Select Python package based on version string
  pythonPkg =
    if pythonVersion == "3.9" then pkgs.python39
    else if pythonVersion == "3.10" then pkgs.python310
    else if pythonVersion == "3.11" then pkgs.python311
    else if pythonVersion == "3.12" then pkgs.python312
    else if pythonVersion == "3.13" then pkgs.python313
    # Note: Python 3.14 is not yet in nixpkgs-unstable
    else throw "Unsupported Python version: ${pythonVersion}. Supported: 3.9, 3.10, 3.11, 3.12, 3.13";
  packages = import ../lib/packages.nix {inherit pkgs;};
  inherit (pkgs) lib;
in pkgs.mkShell {
  name = "${projectName}-shell";

  buildInputs =
    (packages.python.core pythonPkg)
    ++ packages.common.lsp
    ++ lib.optionals withMolten packages.python.molten
    ++ extraPackages;

  shellHook = ''
    echo "🐍 Python Development Environment: ${projectName}"
    echo "Python version: $(python --version)"
    echo "uv version: $(uv --version)"

    # Create virtual environment if it doesn't exist
    if [ ! -d .venv ]; then
      echo "Creating virtual environment..."
      uv venv
    fi

    # Activate the virtual environment
    source .venv/bin/activate

    # Install base requirements if requirements.txt exists
    if [ -f requirements.txt ] && ! python -c "import importlib.util; exit(0 if importlib.util.find_spec('pip') else 1)" 2>/dev/null; then
      echo "Installing requirements..."
      uv pip install -r requirements.txt
    fi

    ${if withMolten then ''
      # Install Molten dependencies
      if ! python -c "import pynvim" 2>/dev/null; then
        echo "Installing molten-nvim dependencies..."
        uv pip install pynvim jupyter-client ipykernel jupytext nbformat
        uv pip install cairosvg pnglatex plotly kaleido pyperclip
      fi

      # Register Jupyter kernel
      if ! jupyter kernelspec list | grep -q "python3.*\.venv"; then
        echo "Registering Jupyter kernel..."
        python -m ipykernel install --user --name=${projectName}-kernel --display-name="${projectName}"
      fi
    '' else ""}

    echo "✅ Environment ready!"
  '';

  # Export Jupyter path for molten-nvim
  JUPYTER_PATH = if withMolten then "$PWD/.venv/share/jupyter" else "";
}