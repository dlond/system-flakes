{
  description = "C++ low-latency development environment for high-performance systems";

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
        llvmVersion = "18"; # Stable for production
      };

      # ============================================================================
      # Configuration - Only specify what's different from defaults
      # ============================================================================
      config = {
        cpp.essential = {
          # Non-variant options (apply to both debug and release)
          cppStandard = 23; # Latest features for performance
          enableExceptions = false; # Avoid exception overhead
          enableRTTI = false; # Avoid RTTI overhead
          warningLevel = "extra"; # Maximum warnings

          # Release-specific overrides (debug uses defaults: O0, no LTO, etc.)
          release = {
            optimizationLevel = 3; # Maximum optimization
            enableLTO = true; # Essential for performance
            useThinLTO = true; # Thin LTO for faster builds
            marchNative = true; # CPU-specific optimizations
            alignForCache = true; # Cache-line alignment
          };
        };
        cpp.performance = {
          enable = true;  # Enable performance packages
          enableBenchmarks = true; # Performance benchmarking
        };
        cpp.linuxPerf = {
          enable = true;  # Enable Linux performance tools
        };
      };
    in {
      # Create development shell with the configuration above
      devShells.default = packages.cpp.mkShell {
        inherit pkgs config;
        name = "C++ Low-Latency Development";
      };
    });
}
