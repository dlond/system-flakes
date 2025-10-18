{
  description = "C++ development environment with Conan and CMake presets";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";
    flake-utils.url = "github:numtide/flake-utils";
    system-flakes = {
      url = "github:dlond/system-flakes";
      # For local development: url = "path:/Users/dlond/dev/projects/system-flakes";
    };
  };

  outputs = { self, nixpkgs, flake-utils, system-flakes, ... }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      
      # Import packages from system-flakes - minimal LLVM for tools only
      packages = import "${system-flakes}/lib/packages.nix" {
        inherit pkgs;
        llvmVersion = "18"; # Version for clangd, clang-format, lldb-dap
      };
      
      # Minimal C++ tools - Conan will handle the actual toolchain
      cppTools = with packages.llvmPkg; [
        clang-tools  # clangd, clang-format, clang-tidy for Neovim
        lldb         # lldb-dap for debugging in Neovim
      ] ++ (with pkgs; [
        cmake
        cmake-format
        cmake-language-server
        ninja
        ccache
        conan
        bear  # For compile_commands.json generation
      ]);
      
    in {
      devShells.default = pkgs.mkShell {
        name = "cpp-dev";
        
        buildInputs = cppTools ++ [
          # Core tools from system-flakes
          packages.core.essential
          packages.core.search
        ];
        
        shellHook = ''
          echo "C++ development environment (Conan-managed)"
          echo "Conan: $(conan --version)"
          echo "CMake: $(cmake --version | head -1)"
          echo ""
          echo "Setup steps:"
          echo "  1. Configure Conan profiles: conan profile detect --force"
          echo "  2. Install deps: conan install . --build=missing"
          echo "  3. Configure: cmake --preset conan-default"
          echo "  4. Build: cmake --build --preset conan-release"
          echo ""
          echo "Available tools (for Neovim integration):"
          echo "  clangd          - Language server"
          echo "  clang-format    - Code formatter"
          echo "  clang-tidy      - Static analyzer"
          echo "  cmake-language-server - CMake LSP"
          echo "  lldb-dap        - DAP debugger"
          echo ""
          echo "Note: Compiler toolchain is managed by Conan profiles"
          
          # Check for Conan profiles
          if [ ! -d ~/.conan2/profiles ]; then
            echo ""
            echo "No Conan profiles found. Run 'conan profile detect --force' to create default profile."
          fi
          
          # Check for conanfile
          if [ ! -f conanfile.txt ] && [ ! -f conanfile.py ]; then
            echo ""
            echo "No conanfile found. Create conanfile.txt or conanfile.py to define dependencies."
          fi
          
          # Check for CMakePresets.json
          if [ ! -f CMakePresets.json ] && [ ! -f CMakeUserPresets.json ]; then
            echo ""
            echo "No CMake presets found. Run 'conan install' to generate CMakePresets.json"
          fi
        '';
        
        # Don't set CC/CXX - let Conan profiles handle it
        # CMAKE_EXPORT_COMPILE_COMMANDS will be set in CMakePresets.json
      };
    });
}