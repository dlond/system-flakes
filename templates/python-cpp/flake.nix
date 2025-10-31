{
  description = "Python + C++ development environment (for bindings, mixed projects)";

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

      # Import packages from system-flakes with versions
      packages = import "${system-flakes}/lib/packages.nix" {
        inherit pkgs;
        pythonVersion = "3.12"; # Change as needed
        llvmVersion = "18"; # For tools only
      };

      # Python with essential packages for Neovim
      pythonEnv = packages.pythonPkg.withPackages (ps:
        with ps; [
          debugpy
          pynvim
          jupyter-client
          ipykernel
          # Add pybind11 or nanobind for bindings if needed
          pybind11
          setuptools
          wheel
          build
        ]);

      # Minimal C++ tools - Conan handles toolchain
      cppTools = with packages.llvmPkg;
        [
          clang-tools # clangd, clang-format, clang-tidy
          lldb # lldb-dap for debugging
        ]
        ++ (with pkgs; [
          cmake
          cmake-format
          cmake-language-server
          ninja
          ccache
          conan
          bear
        ]);
    in {
      devShells.default = pkgs.mkShell {
        name = "python-cpp-dev";

        buildInputs =
          [
            # Python environment and tools
            pythonEnv
            pkgs.uv
            pkgs.basedpyright
            pkgs.ruff
            packages.pythonPkg.pkgs.pytest # Testing framework (matches Python version)

            # C++ tools
          ]
          ++ cppTools
          ++ [
            # Core tools
            packages.core.essential
            packages.core.search

            # For Jupyter/visualization
            pkgs.imagemagick
            pkgs.poppler-utils
          ];

        shellHook = ''
          echo "Python + C++ development environment"
          echo "Python: $(python --version)"
          echo "Conan: $(conan --version)"
          echo "CMake: $(cmake --version | head -1)"
          echo ""
          echo "For Python:"
          echo "  uv venv                     # Create virtual environment"
          echo "  source .venv/bin/activate   # Activate venv"
          echo "  uv pip install -e .         # Install package in editable mode"
          echo ""
          echo "For C++ with Python bindings:"
          echo "  conan install . --build=missing"
          echo "  cmake --preset conan-default -DPYTHON_EXECUTABLE=$(which python)"
          echo "  cmake --build --preset conan-release"
          echo ""
          echo "For pure C++ components:"
          echo "  Use standard Conan + CMake presets workflow"
          echo ""
          echo "Available tools:"
          echo "  Python: basedpyright, ruff, debugpy"
          echo "  C++: clangd, clang-format, lldb-dap"
          echo "  Build: cmake, ninja, conan"

          # Check setup
          if [ ! -d .venv ]; then
            echo ""
            echo "No .venv found. Run 'uv venv' for Python dependencies."
          fi

          if [ ! -f conanfile.txt ] && [ ! -f conanfile.py ]; then
            echo ""
            echo "No conanfile found for C++ dependencies."
          fi
        '';

        # Python for uv
        UV_PROJECT_ENVIRONMENT = ".venv";

        # Don't set CC/CXX - let Conan handle it
        # Python executable for CMake FindPython
        Python3_EXECUTABLE = "${pythonEnv}/bin/python";
      };
    });
}
