{
  description = "C++ low-latency development environment for high-performance systems";

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

      # ============================================================================
      # Configuration - Single source of truth for low-latency systems
      # ============================================================================
      config = {
        # Compiler settings
        llvmVersion = "18";  # Stable for production
        cppStandard = "23";  # Latest features for performance

        # Build settings
        buildType = "Release";
        enableLTO = true;        # Essential for performance
        enableExceptions = false;  # Avoid exception overhead
        enableRTTI = false;      # Avoid RTTI overhead

        # Testing
        enableTesting = true;
        testFramework = "gtest";
        enableBenchmarks = true;   # Performance benchmarking
        enableCoverage = false;

        # Development tools
        enableSanitizers = false;  # Only in Debug builds
        enableClangTidy = false;   # Disable for faster builds
        enableCppCheck = false;
        enableIncludeWhatYouUse = false;

        # Project structure
        buildSharedLibs = false;  # Static for performance
        generateCompileCommands = true;

        # Optimization flags (Release mode)
        optimizationLevel = "3";  # Maximum optimization
        marchNative = true;       # CPU-specific optimizations
        useThinLTO = true;       # Thin LTO for faster builds

        # Additional performance flags
        enableFastMath = false;   # Keep precise math by default
        alignForCache = true;     # Cache-line alignment

        # Warning levels
        warningLevel = "extra";   # Maximum warnings
      };

      # Import packages from system-flakes
      packages = import "${system-flakes}/lib/packages.nix" {
        inherit pkgs;
        llvmVersion = config.llvmVersion;
        packageManager = "conan";
        testFramework = config.testFramework;
        withAnalysis = config.enableClangTidy;
        withBenchmark = config.enableBenchmarks;
      };

      cppEnv = packages.cpp.default;
      helpers = packages.cpp.helpers;

      # Additional performance libraries (specific to low-latency)
      performanceLibs = with pkgs; [
        gbenchmark
        boost
        jemalloc
        mimalloc
        tbb
        catch2_3  # Additional testing framework
      ];

      # Linux-specific performance tools
      linuxTools = pkgs.lib.optionals pkgs.stdenv.isLinux (with pkgs; [
        perf-tools
        valgrind
        liburing
        dpdk
      ]);

      # Use shared helpers to generate profiles and environment
      hostProfile = helpers.mkConanProfile { inherit config pkgs; };
      buildProfile = hostProfile;
      cmakeEnv = helpers.mkCMakeEnv config;
    in {
      devShells.default = pkgs.mkShell (cmakeEnv // {
        name = "cpp-lowlat-dev";

        nativeBuildInputs =
          cppEnv
          ++ performanceLibs
          ++ linuxTools
          ++ [
            # Core tools from system-flakes
            packages.core.essential
            packages.core.search
          ];

        CONAN_PROFILE_HOST = "${hostProfile}";
        CONAN_PROFILE_BUILD = "${buildProfile}";

        shellHook = ''
          echo "C++ Low-Latency Development Environment"
          echo "========================================"
          ${helpers.mkConfigSummary config}
          echo "  Optimization: -O${config.optimizationLevel}"
          ${pkgs.lib.optionalString config.alignForCache ''echo "  Cache Alignment: ON"''}
          echo ""
          ${helpers.mkPerfFlagsSummary config}
          echo ""
          echo "Tools:"
          echo "  Clang: $(clang --version | head -1)"
          echo "  CMake: $(cmake --version | head -1)"
          echo "  Conan: $(conan --version)"
          echo ""
          echo "Setup steps:"
          echo "  1. Install deps:"
          echo "     > conan install . --build=missing --profile:host=$\{CONAN_PROFILE_HOST} --profile:build=$\{CONAN_PROFILE_BUILD}"
          echo "  2. Configure:"
          echo "     > cmake --preset=conan-release"
          echo "  3. Build:"
          echo "     > cmake --build --preset=conan-release"
          echo "  4. Benchmark:"
          echo "     > ./build/bench_orderbook"
          echo ""
          echo "Note: All build settings are configured in flake.nix"
        '';
      });
    });
}