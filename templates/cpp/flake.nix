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

          CONAN_PROFILE_HOST = "${env.profile}";
          CONAN_PROFILE_BUILD = "${env.profile}";

          shellHook = ''
            echo "C++ Development Environment"
            echo "================================"
            ${env.configSummary}
            echo ""
            echo "Tools:"
            echo "  Conan: $(conan --version)"
            echo "  CMake: $(cmake --version | head -1)"
            echo "  Clang: $(clang --version | head -1)"
            echo ""
            echo "Setup steps:"
            echo "  1. Install deps:"
            echo "     > conan install . --build=missing --profile:host=$\{CONAN_PROFILE_HOST} --profile:build=$\{CONAN_PROFILE_BUILD}"
            echo "  2. Configure:"
            echo "     > cmake --preset=conan-release"
            echo "  3. Build:"
            echo "     > cmake --build --preset=conan-release"
            echo ""
            echo "Note: All build settings are configured in flake.nix"
          '';
        });
    });
}
