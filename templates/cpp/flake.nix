{
  description = "C++ development environment with Conan and CMake presets";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    system-flakes = {
      # url = "github:dlond/system-flakes";
      url = "path:/Users/dlond/dev/worktrees/system-flakes/refactor-dev-flakes-235";
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
        llvmVersion = "20";  # Latest LLVM/Clang
      };

      # ============================================================================
      # Configuration - Only specify what's different from defaults
      # ============================================================================
      config = {
        cpp.essential = {
          cppStandard = 23;  # Use latest standard
        };
        cpp.devTools = {
          enableClangTidy = true;  # Enable linting for standard development
        };
      };
    in {
      # Create development shell with the configuration above
      devShells.default = packages.cpp.mkShell {
        inherit pkgs config;
        name = "C++ Development";
      };
    });
}
