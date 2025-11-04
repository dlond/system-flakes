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

      # ============================================================================
      # Configuration - Single source of truth for low-latency systems
      # ============================================================================
      config = {
        # Compiler settings
        llvmVersion = "18"; # Stable for production
        cppStandard = "23"; # Latest features for performance

        # Build settings
        buildType = "Release";
        enableLTO = true; # Essential for performance
        enableExceptions = false; # Avoid exception overhead
        enableRTTI = false; # Avoid RTTI overhead

        # Testing
        enableTesting = true;
        testFramework = "gtest";
        enableBenchmarks = true; # Performance benchmarking
        enableCoverage = false;

        # Development tools
        enableSanitizers = false; # Only in Debug builds
        enableClangTidy = false; # Disable for faster builds
        enableCppCheck = false;
        enableIncludeWhatYouUse = false;

        # Project structure
        buildSharedLibs = false; # Static for performance
        generateCompileCommands = true;

        # Optimization flags (Release mode)
        optimizationLevel = "3"; # Maximum optimization
        marchNative = true; # CPU-specific optimizations
        useThinLTO = true; # Thin LTO for faster builds

        # Additional performance flags
        enableFastMath = false; # Keep precise math by default
        alignForCache = true; # Cache-line alignment

        # Warning levels
        warningLevel = "extra"; # Maximum warnings
      };

      # Import packages from system-flakes
      packages = import "${system-flakes}/lib/packages.nix" {
        inherit pkgs;
      };

      # Use the low-latency C++ environment builder
      env = packages.cpp.environments.mkLowLatencyEnv {
        config =
          config
          // {
            additionalTestFrameworks = true; # Include catch2_3
            enableDPDK = true; # Include DPDK on Linux
          };
        inherit pkgs;
      };
      helpers = packages.cpp.helpers;
    in {
      devShells.default = pkgs.mkShell (env.cmakeEnv
        // {
          name = "cpp-lowlat-dev";

          nativeBuildInputs = env.packages;

          shellHook = ''
            # Set Conan to use local profile directory
            export CONAN_HOME=$(pwd)/.conan2
            mkdir -p $CONAN_HOME/profiles

            # Link global Conan cache and settings (if they exist)
            if [ -d "$HOME/.conan2" ]; then
              # Link all subdirectories except profiles (cache, settings, etc.)
              for conanDir in $(fd -td -d1 -Eprofiles . $HOME/.conan2 2>/dev/null || true); do
                ln -sfn $conanDir $CONAN_HOME/
              done
            fi

            # Link our Nix-generated profiles
            ln -sf ${env.profiles.release} $CONAN_HOME/profiles/default
            ln -sf ${env.profiles.release} $CONAN_HOME/profiles/release
            ln -sf ${env.profiles.debug} $CONAN_HOME/profiles/debug

            echo "C++ Low-Latency Development Environment"
            echo "========================================"
            ${env.configSummary}
            echo "  Optimization: -O${config.optimizationLevel}"
            ${pkgs.lib.optionalString config.alignForCache ''echo "  Cache Alignment: ON"''}
            echo ""
            ${env.perfFlagsSummary}
            echo ""
            echo "Tools:"
            echo "  Clang: $(clang --version | head -1)"
            echo "  CMake: $(cmake --version | head -1)"
            echo "  Conan: $(conan --version)"
            echo ""
            echo "Setup steps:"
            echo ""
            echo "  Debug build (with sanitizers):"
            echo "    > conan install . --profile=debug --build=missing"
            echo "    > cmake --preset=conan-debug"
            echo "    > cmake --build --preset=conan-debug"
            echo ""
            echo "  Release build (optimized):"
            echo "    > conan install . --profile=release --build=missing"
            echo "    > cmake --preset=conan-release"
            echo "    > cmake --build --preset=conan-release"
            echo "    > ./build/Release/bench_orderbook"
            echo ""
            echo "Note: Both debug and release profiles are available"
            echo "      Debug includes sanitizers for testing"
            echo "      Release is optimized for benchmarking"
          '';
        });
    });
}
