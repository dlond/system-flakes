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

      llvm = pkgs.llvmPackages;
      llvmMajor = pkgs.lib.versions.major llvm.release_version;
      appleSdk = pkgs.apple-sdk_26;
      sdkPath = "${appleSdk}/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk";

      warnFlags = [
        "-Wall"
        "-Wextra"
        "-Wpedantic"

        "-Wconversion"
        "-Wsign-conversion"
        "-Wshadow"

        "-Wnon-virtual-dtor"
        "-Woverloaded-virtual"
        "-Wold-style-cast"

        "-Wnull-dereference"
        "-Wdouble-promotion"

        "-Wformat=2"
        "-Wimplicit-fallthrough"
      ];
      cFlags = {
        Base = [
          "-isysroot=${sdkPath}"
        ];
        Debug = [
          "-fsanitize=address,undefined"
        ];
        Release = [];
      };

      cxxFlags = {
        Base =
          cFlags.Base
          ++ warnFlags
          ++ [
            "-I${llvm.libcxx.dev}/include/c++/v1"
            "-stdlib=libc++"
          ];
        Debug = [
          "-O0"
          "-g"
          "-fno-omit-frame-pointer"
          "-fsanitize=address,undefined"
          "-fno-sanitize-recover=all"
        ];
        Release = [
          "-O3"
          "-DNDEBUG"
          "-fstrict-aliasing"
          "-ffp-contract=fast" # fuse FMA where sensible
          "-fno-math-errno"
          "-mcpu=apple-m1" # M1/M1 Max; tweak if you want generic
          "-fvisibility=hidden"
          "-fvisibility-inlines-hidden"
          "-flto=thin"
        ];
        ReleaseFast =
          cxxFlags.Release
          ++ [
            "-fomit-frame-pointer"
            "-funroll-loops"
            "-fno-trapping-math"
            "-fno-signaling-nans"
            "-ffast-math"
          ];
      };

      ldFlags = {
        Base = [
          "-fuse-ld=lld"
        ];
        Debug = [
          "-fsanitize=address,undefined"
        ];
        Release = [
          "-flto=thin"
        ];
      };

      mkFlagsList = flags: "[${pkgs.lib.concatStringsSep ", " (map (f: ''"${f}"'') flags)}]";

      mkConanProfile = buildType:
        pkgs.writeText "conan-profile-${buildType}" ''
          [settings]
          os=Macos
          arch=armv8
          compiler=clang
          compiler.version=${llvmMajor}
          compiler.libcxx=libc++
          compiler.cppstd=23
          build_type=${buildType}

          [conf]
          tools.build:compiler_executables={"c": "${llvm.clang-unwrapped}/bin/clang", "cpp": "${llvm.clang-unwrapped}/bin/clang++"}

          # sysroot + c++ stdlib headers
          tools.build:cflags=${mkFlagsList cFlags.Base}
          tools.build:cxxflags=${mkFlagsList cxxFlags.Base}

          # ${buildType} compile options
          tools.build:cflags+=${mkFlagsList cFlags."${buildType}"}
          tools.build:cxxflags+=${mkFlagsList cxxFlags."${buildType}"}

          # base linker flags
          tools.build:sharedlinkflags=${mkFlagsList ldFlags.Base}
          tools.build:exelinkflags=${mkFlagsList ldFlags.Base}

          # ${buildType} linker flags
          tools.build:sharedlinkflags+=${mkFlagsList ldFlags."${buildType}"}
          tools.build:exelinkflags+=${mkFlagsList ldFlags."${buildType}"}

          tools.cmake.cmaketoolchain:generator=Ninja
          tools.build:jobs=12
        '';

      debugProfile = mkConanProfile "Debug";
      releaseProfile = mkConanProfile "Release";

      llvmPackages = with llvm; [
        clang-unwrapped
        clang-tools
        lld
        libcxx
        libcxx.dev
        libunwind
        compiler-rt-libc
        lldb
      ];
      tools = with pkgs; [
        appleSdk
        cmake
        ninja
        cmake-format
        cmake-language-server
        ccache
        gtest
      ];
    in {
      devShells.default = pkgs.mkShell {
        name = "C++_LLVM_SDK26";
        nativeBuildInputs = llvmPackages ++ tools;
        TESTING_FRAMEWORK = "gtest";
        shellHook = ''
          echo "== Setting up LLVM toolchain with SDK 26 =="

          if [ -z "''${CONAN_HOME:-}" ]; then
            echo "WARNING: CONAN_HOME is not set. Set in .envrc as:"
            echo "  export CONAN_HOME=\$PWD/.conan2"
            return
          fi

          echo "Linking $HOME/.conan2 cache to local CONAN_HOME"
          mkdir -p "$CONAN_HOME/profiles"
          if [ -d "$HOME/.conan2" ]; then
            for dir in $(fd -td -d1 -Eprofiles . "$HOME/.conan2" 2>/dev/null || true); do
              ln -sfn "$dir" "$CONAN_HOME/"
            done
          fi

          echo "Creating local conan profiles"
          ln -sf ${releaseProfile} $CONAN_HOME/profiles/default
          ln -sf ${releaseProfile} $CONAN_HOME/profiles/release
          ln -sf ${debugProfile} $CONAN_HOME/profiles/debug
        '';
      };
    });
}
