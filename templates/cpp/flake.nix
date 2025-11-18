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
        # Basic settings - always customize these
        basic = {
          name = "C++ Development";
          llvmVersion = "20";
          cppStandard = 23;
          compiler = "clang";
        };

        # Development tools - toggle features
        tools = {
          enableClangTidy = true;
          enableCcache = true;
          ccacheMaxSize = "5G";
          enableTesting = true;
          testFramework = "gtest";
        };

        # Advanced settings - optimization & performance
        advanced = {
          buildJobs = 12;
          defaultProfile = "release";
          warningLevel = "all";
          enableExceptions = true;
          enableRTTI = true;

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
        };
      };

      # ============================================================================
      # Package selection
      # ============================================================================
      llvmPkg = pkgs."llvmPackages_${config.basic.llvmVersion}";

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
        ++ lib.optionals config.tools.enableTesting [
          gtest
        ];

      # ============================================================================
      # Helper functions
      # ============================================================================

      # Build compiler flags
      mkCxxFlags = variant:
        lib.concatStringsSep " " (
          ["-O${toString config.advanced.${variant}.optimizationLevel}"]
          ++ lib.optionals config.advanced.${variant}.marchNative ["-march=native" "-mtune=native"]
          ++ lib.optionals config.advanced.${variant}.enableLTO [
            (
              if config.advanced.${variant}.useThinLTO or false
              then "-flto=thin"
              else "-flto"
            )
          ]
          ++ lib.optionals (!config.advanced.enableExceptions) ["-fno-exceptions"]
          ++ lib.optionals (!config.advanced.enableRTTI) ["-fno-rtti"]
          ++ lib.optionals (config.advanced.${variant}.enableFastMath or false) ["-ffast-math"]
          ++ lib.optionals (config.advanced.${variant}.alignForCache or false) ["-falign-functions=64"]
        );

      # Build linker flags
      mkLdFlags = variant:
        lib.concatStringsSep " " (
          ["-fuse-ld=lld"]
          ++ lib.optionals config.advanced.${variant}.enableLTO [
            (
              if config.advanced.${variant}.useThinLTO or false
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
          compiler=${config.basic.compiler}
          compiler.version=${config.basic.llvmVersion}
          compiler.libcxx=${
            if config.basic.compiler == "clang"
            then "libc++"
            else "libstdc++11"
          }
          compiler.cppstd=${toString config.basic.cppStandard}
          build_type=${buildType}

          [conf]
          tools.cmake.cmaketoolchain:generator=Ninja
          tools.build:jobs=${toString config.advanced.buildJobs}
          ${lib.optionalString config.tools.enableCcache ''
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
        name = config.basic.name;
        nativeBuildInputs = packages;
        ENV_ICON = "❄️";

        # CMake environment variables
        CMAKE_CXX_STANDARD = toString config.basic.cppStandard;
        CMAKE_EXPORT_COMPILE_COMMANDS = "ON";
        ENABLE_TESTING =
          if config.tools.enableTesting
          then "ON"
          else "OFF";
        ENABLE_CLANG_TIDY =
          if config.tools.enableClangTidy
          then "ON"
          else "OFF";

        CCACHE_DIR = "$HOME/.ccache";
        CCACHE_MAXSIZE = config.tools.ccacheMaxSize;

        shellHook = ''
          if [ ! -d ".git" ]; then
            git init
          fi

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
          echo "🚀 ${config.basic.name}"
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
