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

      # ============================================================================
      # Configuration - Single source of truth for the project
      # ============================================================================
      config = {
        # Compiler settings
        llvmVersion = "20";
        cppStandard = "23";

        # Build settings
        buildType = "Release"; # Default build type
        defaultProfile = "release"; # Which profile to use as default (debug/release)
        enableLTO = false; # Link-time optimization
        enableExceptions = true;
        enableRTTI = true;

        # Testing
        enableTesting = true;
        testFramework = "gtest"; # gtest, catch2, doctest
        enableCoverage = false;

        # Development tools
        enableSanitizers = false; # Address & UB sanitizers in Debug
        enableClangTidy = true;
        enableCppCheck = false;
        enableIncludeWhatYouUse = false;

        # Project structure
        buildSharedLibs = false;
        generateCompileCommands = true;

        # Optimization flags (Release mode)
        optimizationLevel = "2"; # 0, 1, 2, 3, s, z
        marchNative = false;

        # Warning levels
        warningLevel = "all"; # none, default, all, extra
      };

      # Import packages from system-flakes
      packages = import "${system-flakes}/lib/packages.nix" {
        inherit pkgs;
      };

      # Use the standard C++ environment builder
      env = packages.cpp.environments.mkStandardEnv {inherit config pkgs;};
      helpers = packages.cpp.helpers;
    in {
      devShells.default = pkgs.mkShell (env.cmakeEnv
        // {
          name = "cpp-dev";

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
            ln -sf ${env.profiles.${config.defaultProfile or "release"}} $CONAN_HOME/profiles/default
            ln -sf ${env.profiles.release} $CONAN_HOME/profiles/release
            ln -sf ${env.profiles.debug} $CONAN_HOME/profiles/debug

            echo "C++ Development Environment"
            echo "================================"
            ${env.configSummary}
            echo ""
            echo "Tools:"
            echo "  Conan: $(conan --version)"
            echo "  CMake: $(cmake --version | head -1)"
            echo "  Clang: $(clang --version | head -1)"
            ${env.ccacheInfo}
            echo ""
            echo "Setup steps:"
            echo ""
            echo "  Debug build:"
            echo "    > conan install . --profile=debug --build=missing"
            echo "    > cmake --preset=conan-debug"
            echo "    > cmake --build --preset=conan-debug"
            echo ""
            echo "  Release build:"
            echo "    > conan install . --profile=release --build=missing"
            echo "    > cmake --preset=conan-release"
            echo "    > cmake --build --preset=conan-release"
            echo ""
            echo "Note: Both debug and release profiles are available"
            echo "      All build settings are configured in flake.nix"
          '';
        });
    });
}
