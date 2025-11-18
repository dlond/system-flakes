{
  description = "C++ development environment with Conan and CMake presets";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      lib = pkgs.lib;

      # ============================================================================
      # Configuration - Modify these to customize your project
      # ============================================================================
      config = {
        name = "C++ Development";

        # Compiler and language settings
        llvmVersion = "20";
        cppStandard = 23;
        compiler = "clang";
        warningLevel = "all";
        enableExceptions = true;
        enableRTTI = true;

        # Build configuration
        buildJobs = 12;
        defaultProfile = "release";

        # Debug build settings
        debug = {
          optimizationLevel = 0;
          enableLTO = false;
          marchNative = false;
          enableSanitizers = true;
          enableCoverage = true;
        };

        # Release build settings
        release = {
          optimizationLevel = 2;
          enableLTO = false;
          useThinLTO = false;
          marchNative = false;
          alignForCache = false;
          enableFastMath = false;
        };

        # Tools and features
        enableClangTidy = true;
        enableCcache = true;
        ccacheMaxSize = "5G";
        enableTesting = true;
        testFramework = "gtest";
      };

      # ============================================================================
      # Package selection
      # ============================================================================
      llvmPkg = pkgs."llvmPackages_${config.llvmVersion}";

      packages = with pkgs;
        [
          # must come before clang to be wrapped:
          # https://blog.kotatsu.dev/posts/2024-04-10-nixpkgs-clangd-missing-headers/
          llvmPkg.clang-tools

          # Compiler and build tools
          llvmPkg.clang
          llvmPkg.lld
          llvmPkg.libcxx
          llvmPkg.libcxx.dev
          cmake
          ninja
          conan

          # Development tools
          cmake-format
          cmake-language-server
          ccache

          # Debugging
          llvmPkg.lldb
        ]
        ++ lib.optionals stdenv.isLinux [
          gdb
          valgrind
        ]
        ++ lib.optionals config.enableTesting [
          gtest
        ];

      # ============================================================================
      # Helper functions
      # ============================================================================

      # Build compiler flags
      mkCxxFlags = variant:
        lib.concatStringsSep " " (
          ["-O${toString config.${variant}.optimizationLevel}"]
          ++ lib.optionals config.${variant}.marchNative ["-march=native" "-mtune=native"]
          ++ lib.optionals config.${variant}.enableLTO [
            (
              if config.${variant}.useThinLTO or false
              then "-flto=thin"
              else "-flto"
            )
          ]
          ++ lib.optionals (!config.enableExceptions) ["-fno-exceptions"]
          ++ lib.optionals (!config.enableRTTI) ["-fno-rtti"]
          ++ lib.optionals (config.${variant}.enableFastMath or false) ["-ffast-math"]
          ++ lib.optionals (config.${variant}.alignForCache or false) ["-falign-functions=64"]
        );

      # Build linker flags
      mkLdFlags = variant:
        lib.concatStringsSep " " (
          ["-fuse-ld=lld"]
          ++ lib.optionals config.${variant}.enableLTO [
            (
              if config.${variant}.useThinLTO or false
              then "-flto=thin"
              else "-flto"
            )
          ]
        );

      # Generate Conan profile
      mkConanProfile = variant: let
        buildType =
          if variant == "debug"
          then "Debug"
          else "Release";
      in
        pkgs.writeText "conan-profile-${variant}" ''
          [settings]
          os=${
            if pkgs.stdenv.isDarwin
            then "Macos"
            else if pkgs.stdenv.isLinux
            then "Linux"
            else "Unknown"
          }
          arch=${
            if pkgs.stdenv.isAarch64
            then "armv8"
            else if pkgs.stdenv.isx86_64
            then "x86_64"
            else "Unknown"
          }
          compiler=${config.compiler}
          compiler.version=${config.llvmVersion}
          compiler.libcxx=${
            if config.compiler == "clang"
            then "libc++"
            else "libstdc++11"
          }
          compiler.cppstd=${toString config.cppStandard}
          build_type=${buildType}

          [conf]
          tools.cmake.cmaketoolchain:generator=Ninja
          tools.build:jobs=${toString config.buildJobs}
          ${lib.optionalString config.enableCcache ''
            tools.cmake.cmaketoolchain:extra_variables={"CMAKE_C_COMPILER_LAUNCHER": "${pkgs.ccache}/bin/ccache", "CMAKE_CXX_COMPILER_LAUNCHER": "${pkgs.ccache}/bin/ccache"}
          ''}

          [buildenv]
          CXXFLAGS=${mkCxxFlags variant}
          LDFLAGS=${mkLdFlags variant}
        '';

      debugProfile = mkConanProfile "debug";
      releaseProfile = mkConanProfile "release";
    in {
      devShells.default = pkgs.mkShell {
        name = config.name;
        nativeBuildInputs = packages;

        # CMake environment variables
        CMAKE_CXX_STANDARD = toString config.cppStandard;
        CMAKE_EXPORT_COMPILE_COMMANDS = "ON";
        ENABLE_TESTING =
          if config.enableTesting
          then "ON"
          else "OFF";
        ENABLE_CLANG_TIDY =
          if config.enableClangTidy
          then "ON"
          else "OFF";

        CCACHE_DIR = "$HOME/.ccache";
        CCACHE_MAXSIZE = config.ccacheMaxSize;

        shellHook = ''
          # Set Conan to use local profile directory
          export CONAN_HOME=$(pwd)/.conan2
          mkdir -p $CONAN_HOME/profiles

          # Link global Conan cache (if it exists)
          if [ -d "$HOME/.conan2" ]; then
            for conanDir in $(fd -td -d1 -Eprofiles . $HOME/.conan2 2>/dev/null || true); do
              ln -sfn $conanDir $CONAN_HOME/
            done
          fi

          # Link Nix-generated profiles
          ln -sf ${releaseProfile} $CONAN_HOME/profiles/default
          ln -sf ${releaseProfile} $CONAN_HOME/profiles/release
          ln -sf ${debugProfile} $CONAN_HOME/profiles/debug

          echo ""
          echo "🚀 ${config.name}"
          echo "─────────────────────────────────"
          echo "Environment ready!"
          echo ""
          echo "Quick start:"
          echo "  Debug:   conan install . --profile=debug --build=missing && cmake --preset=conan-debug"
          echo "  Release: conan install . --profile=release --build=missing && cmake --preset=conan-release"
          echo ""
        '';
      };
    });
}
