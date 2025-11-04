# Single source of truth for all packages across system and dev shells
# System uses defaults, dev-shells can override versions
{
  pkgs,
  # Global version defaults (can be overridden per-language or in dev-shells)
  llvmVersion ? "20", # System default: LLVM 20
  pythonVersion ? "3.13", # System default: Python 3.13 (stable)
  ...
}: let
  inherit (pkgs) lib;

  # Package selectors based on versions
  selectLLVM = version:
    pkgs."llvmPackages_${version}" or pkgs.llvmPackages;

  selectPython = version: let
    ver = lib.concatStrings (lib.splitString "." version);
  in
    pkgs."python${ver}";

  # Default package selections
  llvmPkg = selectLLVM llvmVersion;
  pythonPkg = selectPython pythonVersion;
  # Python with essential packages for system-wide use
  pythonWithEssentials = pythonPkg.withPackages (ps:
    with ps; [
      debugpy # Python DAP debugging
      pynvim # Neovim Python host
      jupyter-client # Molten communication with kernels
      ipykernel # Create Python kernels
    ]);
in rec {
  # Export the base packages for reference
  inherit pythonPkg pythonWithEssentials llvmPkg;

  # Core tools needed everywhere (system + all dev shells)
  core = {
    # Essential development tools
    essential = with pkgs; [
      git
      gnumake
      gcc # For compiling native extensions
      pkg-config
      gnused # GNU sed for consistent behavior across platforms
    ];

    # Search and navigation tools (needed by neovim)
    search = with pkgs; [
      ripgrep # Fast grep, required by telescope.nvim
      fd # Fast find, required by telescope.nvim
      tree # Directory visualization
    ];

    # File and data tools
    utils = with pkgs; [
      curl
      wget
      unzip
      zip
      jq # JSON processor
      yq-go # YAML processor
    ];
  };

  # C++ development packages
  cpp = rec {
    # ============================================================================
    # Main API for templates - single entry point
    # ============================================================================
    mkShell = {
      pkgs,
      config ? {},  # User config (partial)
      name ? "cpp-dev",  # Optional shell name
      extraPackages ? [],  # Optional extra packages
    }: let
      # Apply defaults to get complete config
      defaults = helpers.mkConfigDefaults {};
      finalConfig = lib.recursiveUpdate defaults config;
      cfg = finalConfig.cpp;  # Shorthand

      # Compose packages based on config
      packages = essential
        ++ core.essential
        ++ core.search
        ++ lib.optionals (cfg.devTools.enable or true) devTools
        ++ lib.optionals (cfg.devTools.enableCcache or true) [pkgs.ccache]
        ++ lib.optionals (cfg.devTools.enablePreCommitHooks or false) [pkgs.pre-commit]
        ++ debugging  # Always include
        ++ lib.optionals (cfg.analysis.enable or false) analysis
        ++ lib.optionals (cfg.docs.enable or false) docs
        ++ lib.optionals (cfg.testing.enable or true) (testFrameworks.${cfg.testing.testFramework or "gtest"} or [])
        ++ lib.optionals (cfg.performance.enable or false) performance
        ++ lib.optionals (cfg.linuxPerf.enable or false) linuxPerf  # linuxPerf already checks isLinux
        ++ extraPackages;

      # Flatten config for compatibility with existing helpers
      flatConfig = cfg.essential // {
        enableCcache = cfg.devTools.enableCcache or true;
        ccacheMaxSize = cfg.devTools.ccacheMaxSize or "5G";
        enableClangTidy = cfg.devTools.enableClangTidy or false;
        enablePreCommitHooks = cfg.devTools.enablePreCommitHooks or false;
        enableCppCheck = cfg.analysis.enableCppCheck or false;
        enableIncludeWhatYouUse = cfg.analysis.enableIncludeWhatYouUse or false;
        enableDocs = cfg.docs.enableDocs or false;
        enableTesting = cfg.testing.enableTesting or true;
        testFramework = cfg.testing.testFramework or "gtest";
        enableCoverage = cfg.testing.enableCoverage or false;
        enableSanitizers = cfg.testing.enableSanitizers or false;
        enableBenchmarks = cfg.performance.enableBenchmarks or false;
      };

      # Get environment setup
      conan = helpers.mkConanSetup {config = flatConfig; inherit pkgs;};
      cmakeEnv = helpers.mkCMakeEnv flatConfig;
      preCommitHook = helpers.mkPreCommitHook flatConfig;
      docsSetup = helpers.mkDocsSetup flatConfig;

      # Generate README content
      readmeContent = helpers.mkReadme {
        inherit name cfg;
        config = flatConfig;
      };
    in
      pkgs.mkShell (cmakeEnv // {
        inherit name;
        nativeBuildInputs = packages;

        shellHook = ''
          ${conan.setup}
          ${preCommitHook}
          ${docsSetup}

          # Generate README.md if it doesn't exist or is outdated
          if [ ! -f README.md ] || [ flake.nix -nt README.md ]; then
            echo "Generating README.md based on configuration..."
            cat > README.md << 'EOF'
          ${readmeContent}
          EOF
          fi

          # Minimal output
          echo ""
          echo "🚀 ${name}"
          echo "─────────────────────────────────"
          echo "Environment ready. See README.md for documentation."
          echo ""
          echo "Quick start:"
          echo "  Debug:   conan install . --profile=debug --build=missing && cmake --preset=conan-debug"
          echo "  Release: conan install . --profile=release --build=missing && cmake --preset=conan-release"
          echo ""
        '';
      });

    # ============================================================================
    # Internal Implementation - Not for template use
    # ============================================================================
    helpers = rec {
      # Generate README.md content based on configuration
      mkReadme = {name, cfg, config}: let
        isLowLat = cfg.performance.enable or false;
        hasLTO = cfg.essential.enableLTO or false;
        hasBenchmarks = cfg.performance.enableBenchmarks or false;
        hasDocs = config.enableDocs or false;
        hasAnalysis = config.enableCppCheck or config.enableIncludeWhatYouUse or false;
        optimLevel = toString (cfg.essential.optimizationLevel or 2);
      in ''
# ${name}

${if isLowLat then "High-performance C++ development environment optimized for low-latency systems."
  else "Modern C++ development environment with Conan package management and CMake build system."}

## Features

${if isLowLat then ''- ⚡ **Maximum Performance** - Aggressive optimizations enabled
- 🚀 **C++${toString cfg.essential.cppStandard}** - Latest language features
${if hasLTO then "- 🔥 **LTO** - Link-time optimization enabled" + (if cfg.essential.useThinLTO or false then " (ThinLTO)" else "") + "\n" else ""}${if cfg.essential.marchNative or false then "- 🎯 **CPU-Specific** - Native architecture targeting\n" else ""}${if hasBenchmarks then "- 📊 **Benchmarking** - Performance measurement tools\n" else ""}${if cfg.essential.alignForCache or false then "- 💾 **Cache Alignment** - Optimized for cache lines\n" else ""}${if cfg.linuxPerf.enable or false then "- 🐧 **Linux Perf Tools** - Advanced profiling capabilities\n" else ""}''
  else ''- 🚀 **C++${toString cfg.essential.cppStandard}** - Modern C++ standard
- 📦 **Conan 2** - Package management
- 🔧 **CMake Presets** - Consistent build configuration
- 🛠️ **LLVM Toolchain** - Latest compiler
${if config.enableClangTidy or false then "- 🔍 **clang-tidy** - Static analysis\n" else ""}${if config.enableCcache or true then "- ⚡ **ccache** - Build acceleration\n" else ""}${if cfg.testing.enable or true then "- 🧪 **Testing** - " + (cfg.testing.testFramework or "gtest") + " framework\n" else ""}''}

## Configuration

### Configuration Options

All available configuration options with defaults and explanations:

| Option | Default | Description | Current |
|--------|---------|-------------|---------|
| **cpp.essential** | | *Core compilation settings* | |
| \`cppStandard\` | \`20\` | C++ standard version (17, 20, 23) | **${toString cfg.essential.cppStandard}** |
| \`defaultProfile\` | \`"release"\` | Default Conan profile | ${cfg.essential.defaultProfile or "release"} |
| \`enableLTO\` | \`false\` | Link-time optimization | ${if hasLTO then "**true**" else "false"} |
| \`useThinLTO\` | \`false\` | Use ThinLTO (faster than full LTO) | ${if cfg.essential.useThinLTO or false then "**true**" else "false"} |
| \`enableExceptions\` | \`true\` | C++ exception handling | ${if cfg.essential.enableExceptions or true then "true" else "**false**"} |
| \`enableRTTI\` | \`true\` | Runtime type information | ${if cfg.essential.enableRTTI or true then "true" else "**false**"} |
| \`optimizationLevel\` | \`2\` | Optimization (-O0 to -O3, s, z) | ${if optimLevel != "2" then "**" + optimLevel + "**" else "2"} |
| \`marchNative\` | \`false\` | CPU-specific optimizations | ${if cfg.essential.marchNative or false then "**true**" else "false"} |
| \`alignForCache\` | \`false\` | Cache-line alignment (64 bytes) | ${if cfg.essential.alignForCache or false then "**true**" else "false"} |
| \`warningLevel\` | \`"all"\` | Compiler warnings (none/default/all/extra) | ${cfg.essential.warningLevel or "all"} |
| **cpp.devTools** | | *Development productivity tools* | |
| \`enable\` | \`true\` | Include dev tools | ${if cfg.devTools.enable or true then "true" else "**false**"} |
| \`enableClangTidy\` | \`false\` | Static analysis linting | ${if config.enableClangTidy or false then "**true**" else "false"} |
| \`enableCppCheck\` | \`false\` | Additional static analysis | ${if config.enableCppCheck or false then "**true**" else "false"} |
| \`enableCcache\` | \`true\` | Build caching | ${if config.enableCcache or true then "true" else "**false**"} |
| \`ccacheMaxSize\` | \`"5G"\` | Cache size limit | ${cfg.devTools.ccacheMaxSize or "5G"} |
| \`enablePreCommitHooks\` | \`false\` | Git pre-commit hooks | ${if config.enablePreCommitHooks or false then "**true**" else "false"} |
| **cpp.testing** | | *Testing framework configuration* | |
| \`enable\` | \`true\` | Include test framework | ${if cfg.testing.enable or true then "true" else "**false**"} |
| \`testFramework\` | \`"gtest"\` | Framework (gtest/catch2/doctest) | ${cfg.testing.testFramework or "gtest"} |
| \`enableCoverage\` | \`false\` | Code coverage reporting | ${if cfg.testing.enableCoverage or false then "**true**" else "false"} |
| \`enableSanitizers\` | \`false\` | Memory/UB sanitizers (debug) | ${if cfg.testing.enableSanitizers or false then "**true**" else "false"} |
| **cpp.performance** | | *Performance optimization tools* | |
| \`enable\` | \`false\` | Include performance libraries | ${if cfg.performance.enable or false then "**true**" else "false"} |
| \`enableBenchmarks\` | \`false\` | Google Benchmark library | ${if hasBenchmarks then "**true**" else "false"} |
| **cpp.linuxPerf** | | *Linux-specific performance tools* | |
| \`enable\` | \`false\` | DPDK, perf-tools, io_uring | ${if cfg.linuxPerf.enable or false then "**true**" else "false"} |
| **cpp.docs** | | *Documentation generation* | |
| \`enable\` | \`false\` | Include doc tools | ${if cfg.docs.enable or false then "**true**" else "false"} |
| \`enableDocs\` | \`false\` | Doxygen + Sphinx | ${if hasDocs then "**true**" else "false"} |

**Bold** values indicate overrides from defaults.

### Current Configuration

Settings from \`flake.nix\`:

\`\`\`nix
config = {
  cpp.essential = {
    cppStandard = ${toString cfg.essential.cppStandard};${if isLowLat then ''
    enableLTO = ${if hasLTO then "true" else "false"};${if cfg.essential.useThinLTO or false then ''
    useThinLTO = true;'' else ""}
    enableExceptions = ${if cfg.essential.enableExceptions or true then "true" else "false"};
    enableRTTI = ${if cfg.essential.enableRTTI or true then "true" else "false"};
    optimizationLevel = ${optimLevel};${if cfg.essential.marchNative or false then ''
    marchNative = true;'' else ""}${if cfg.essential.alignForCache or false then ''
    alignForCache = true;'' else ""}'' else ""}
  };${if config.enableClangTidy or false then ''
  cpp.devTools = {
    enableClangTidy = true;
  };'' else ""}${if hasBenchmarks then ''
  cpp.performance = {
    enable = true;
    enableBenchmarks = true;
  };'' else ""}${if cfg.linuxPerf.enable or false then ''
  cpp.linuxPerf = {
    enable = true;
  };'' else ""}
};
\`\`\`

## Compiler Flags

**Release Build:**
- \`-O${optimLevel}\` - Optimization level
${if cfg.essential.marchNative or false then "- `-march=native -mtune=native` - CPU-specific instructions\n" else ""}${if hasLTO then "- `-flto" + (if cfg.essential.useThinLTO or false then "=thin" else "") + "` - Link-time optimization\n" else ""}${if !(cfg.essential.enableExceptions or true) then "- `-fno-exceptions` - No exception handling\n" else ""}${if !(cfg.essential.enableRTTI or true) then "- `-fno-rtti` - No RTTI overhead\n" else ""}${if cfg.essential.alignForCache or false then "- `-falign-functions=64` - Cache-line alignment\n" else ""}

**Debug Build:**
- \`-O0 -g3\` - No optimization, full debug info
${if cfg.testing.enableSanitizers or false then "- `-fsanitize=address,undefined` - Memory and UB detection\n" else ""}

## Quick Start

\`\`\`bash
# Enter the development environment
nix develop

# Debug build
conan install . --profile=debug --build=missing
cmake --preset=conan-debug
cmake --build --preset=conan-debug
./build/Debug/app

# Release build
conan install . --profile=release --build=missing
cmake --preset=conan-release
cmake --build --preset=conan-release
./build/Release/app
\`\`\`

## Project Structure

\`\`\`
.
├── flake.nix              # Nix environment configuration
├── CMakeLists.txt         # CMake build configuration
├── conanfile.txt          # Conan dependencies
├── .conan2/               # Local Conan profiles
├── include/               # Header files
├── src/                   # Source files
│   └── main.cpp
${if cfg.testing.enable or true then "├── tests/                 # Unit tests\n" else ""}${if hasBenchmarks then "├── bench/                 # Benchmarks\n" else ""}└── build/                 # Build output (git-ignored)
    ├── Debug/
    └── Release/
\`\`\`

## Adding Dependencies

Add to \`conanfile.txt\`:

\`\`\`ini
[requires]
fmt/10.1.1
spdlog/1.12.0

[generators]
CMakeDeps
CMakeToolchain

[layout]
cmake_layout
\`\`\`

Then reinstall:
\`\`\`bash
conan install . --profile=release --build=missing
cmake --preset=conan-release
\`\`\`

## Tools Included

- **Compiler**: Clang with libc++
- **Build**: CMake, Ninja
- **Package Manager**: Conan 2.x
- **Language Server**: clangd
- **Formatter**: clang-format
${if config.enableClangTidy or false then "- **Static Analysis**: clang-tidy\n" else ""}${if config.enableCppCheck or false then "- **Static Analysis**: cppcheck\n" else ""}${if config.enableCcache or true then "- **Cache**: ccache\n" else ""}${if cfg.testing.enable or true then "- **Testing**: " + (cfg.testing.testFramework or "gtest") + "\n" else ""}${if hasBenchmarks then "- **Benchmarking**: Google Benchmark\n" else ""}${if hasDocs then "- **Documentation**: Doxygen + Sphinx\n" else ""}

## Development Tips

1. **IDE Integration**: The environment generates \`compile_commands.json\` for clangd support
2. **Clean Build**: \`rm -rf build/ && conan install . --profile=release --build=missing\`
3. **Switch Profiles**: Use \`--preset=conan-debug\` or \`--preset=conan-release\`
${if config.enableCcache or true then "4. **Faster Builds**: ccache enabled - subsequent builds will be faster\n" else ""}${if hasBenchmarks then ''
## Benchmarking

\`\`\`cpp
#include <benchmark/benchmark.h>

static void BM_Example(benchmark::State& state) {
    for (auto _ : state) {
        // Code to benchmark
    }
}
BENCHMARK(BM_Example);
\`\`\`

Run: \`./build/Release/bench_app\`
'' else ""}

## Troubleshooting

**Conan packages not found:**
\`\`\`bash
conan remove "*" -c
conan install . --profile=release --build=missing
\`\`\`

**CMake preset not found:**
\`\`\`bash
ls CMakePresets.json  # Should exist after conan install
\`\`\`

**Build errors:**
\`\`\`bash
# Force rebuild dependencies
conan install . --profile=release --build=missing --build=<package>
\`\`\`

---
*Generated by nix develop based on flake.nix configuration*
      '';

      # Get default configuration structure for C++ projects
      mkConfigDefaults = {}: {
        cpp = {
          # Core settings - always applied
          essential = {
            cppStandard = 20;
            defaultProfile = "release";
            enableLTO = false;
            useThinLTO = false;
            enableExceptions = true;
            enableRTTI = true;
            optimizationLevel = 2;
            marchNative = false;
            enableFastMath = false;
            alignForCache = false;
            warningLevel = "all";
          };

          # Development tools - conditionally included
          devTools = {
            enable = true;  # Include by default
            enablePreCommitHooks = false;
            enableCcache = true;
            ccacheMaxSize = "5G";
            enableClangTidy = false;  # These enable checks, don't add packages
          };

          # Debugging - always included
          debugging = {
            # No options - always included when cpp.devTools.enable = true
          };

          # Static analysis - conditionally included
          analysis = {
            enable = false;  # Off by default
            enableCppCheck = false;
            enableIncludeWhatYouUse = false;
          };

          # Documentation - conditionally included
          docs = {
            enable = false;  # Off by default
            enableDocs = false;
          };

          # Testing - conditionally included
          testing = {
            enable = true;  # Include by default
            enableTesting = true;
            testFramework = "gtest";  # gtest, catch2, doctest
            enableCoverage = false;
            enableSanitizers = false;  # For debug builds
          };

          # Performance & benchmarking - conditionally included
          performance = {
            enable = false;  # Off by default
            enableBenchmarks = false;
          };

          # Linux performance - conditionally included (Linux only)
          linuxPerf = {
            enable = false;  # Off by default
            enableDPDK = false;
          };
        };
      };

      # Convert boolean to cmake ON/OFF string
      boolToCMake = b:
        if b
        then "ON"
        else "OFF";

      # Generate CXXFLAGS from config
      mkCxxFlags = config:
        lib.concatStringsSep " " (
          ["-O${toString config.optimizationLevel}"]
          ++ lib.optionals config.marchNative ["-march=native" "-mtune=native"]
          ++ lib.optionals config.enableLTO [
            (
              if config.useThinLTO
              then "-flto=thin"
              else "-flto"
            )
          ]
          ++ lib.optionals (!config.enableExceptions) ["-fno-exceptions"]
          ++ lib.optionals (!config.enableRTTI) ["-fno-rtti"]
          ++ lib.optionals config.enableFastMath ["-ffast-math"]
          ++ lib.optionals config.alignForCache ["-falign-functions=64"]
        );

      # Generate LDFLAGS from config
      mkLdFlags = config:
        lib.concatStringsSep " " (
          ["-fuse-ld=lld"]
          ++ lib.optionals config.enableLTO [
            (
              if config.useThinLTO
              then "-flto=thin"
              else "-flto"
            )
          ]
        );

      # Generate Conan profile from config
      mkConanProfile = {
        config,
        pkgs,
        variant ? "release",
      }: let
        # Apply debug overrides if variant is debug
        finalConfig =
          if variant == "debug"
          then
            config
            // {
              buildType = "Debug";
              optimizationLevel = "0";
              enableSanitizers = true;
              marchNative = false;
            }
          else config;
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
          compiler=${
            if finalConfig.compiler or "clang" == "clang"
            then "clang"
            else "gcc"
          }
          compiler.version=${toString (finalConfig.llvmVersion or llvmVersion)}
          compiler.libcxx=${
            if finalConfig.compiler or "clang" == "clang"
            then "libc++"
            else "libstdc++11"
          }
          compiler.cppstd=${toString (finalConfig.cppStandard or 20)}
          build_type=${finalConfig.buildType or "Release"}

          [conf]
          tools.cmake.cmaketoolchain:generator=Ninja
          tools.build:jobs=${toString (finalConfig.buildJobs or 12)}
          ${lib.optionalString (finalConfig.enableCcache or true) ''
            tools.cmake.cmaketoolchain:extra_variables={"CMAKE_C_COMPILER_LAUNCHER": "${pkgs.ccache}/bin/ccache", "CMAKE_CXX_COMPILER_LAUNCHER": "${pkgs.ccache}/bin/ccache"}
          ''}

          ${lib.optionalString ((finalConfig.buildType or "Release") == "Release" && (finalConfig.enableLTO or false)) ''
            [buildenv]
            CXXFLAGS=${mkCxxFlags finalConfig}
            LDFLAGS=${mkLdFlags finalConfig}
          ''}
        '';

      # Generate both debug and release Conan profiles
      mkConanProfiles = {
        config,
        pkgs,
      }: {
        release = mkConanProfile {
          inherit config pkgs;
          variant = "release";
        };
        debug = mkConanProfile {
          inherit config pkgs;
          variant = "debug";
        };
      };

      # Generate environment variables for CMake
      mkCMakeEnv = config:
        {
          # Essential build configuration
          CMAKE_CXX_STANDARD = toString config.cppStandard;
          CMAKE_EXPORT_COMPILE_COMMANDS = "ON";  # Always generate for LSP

          # C++ feature flags
          ENABLE_LTO = boolToCMake config.enableLTO;
          USE_THIN_LTO = boolToCMake config.useThinLTO;
          ENABLE_EXCEPTIONS = boolToCMake config.enableExceptions;
          ENABLE_RTTI = boolToCMake config.enableRTTI;

          # Testing configuration
          ENABLE_TESTING = boolToCMake config.enableTesting;
          TEST_FRAMEWORK = config.testFramework;
          ENABLE_BENCHMARKS = boolToCMake config.enableBenchmarks;
          ENABLE_COVERAGE = boolToCMake config.enableCoverage;

          # Development tools
          ENABLE_SANITIZERS = boolToCMake config.enableSanitizers;
          ENABLE_CLANG_TIDY = boolToCMake config.enableClangTidy;
          ENABLE_CPPCHECK = boolToCMake config.enableCppCheck;
          ENABLE_IWYU = boolToCMake config.enableIncludeWhatYouUse;
          ENABLE_DOCS = boolToCMake config.enableDocs;

          # Performance/optimization flags
          OPTIMIZATION_LEVEL = toString config.optimizationLevel;
          MARCH_NATIVE = boolToCMake config.marchNative;
          ENABLE_FAST_MATH = boolToCMake config.enableFastMath;
          ALIGN_FOR_CACHE = boolToCMake config.alignForCache;

          # Compiler configuration
          WARNING_LEVEL = config.warningLevel;
        }
        // lib.optionalAttrs config.enableCcache {
          CCACHE_DIR = "$HOME/.ccache";
          CCACHE_MAXSIZE = config.ccacheMaxSize;
        };

      # Generate pre-commit hook installation
      mkPreCommitHook = config:
        lib.optionalString config.enablePreCommitHooks ''
          # Install pre-commit hooks if config exists
          if [ -f .pre-commit-config.yaml ] && command -v pre-commit >/dev/null 2>&1; then
            if [ ! -f .git/hooks/pre-commit ]; then
              echo "Installing pre-commit hooks..."
              pre-commit install --install-hooks >/dev/null 2>&1 || true
            fi
          fi
        '';

      # Generate documentation setup helper
      mkDocsSetup = config:
        lib.optionalString config.enableDocs ''
          # Create docs structure if it doesn't exist
          if [ ! -f docs/conf.py ] && [ -f CMakeLists.txt ]; then
            echo "Setting up documentation structure..."
            mkdir -p docs
            # We'll populate these files in the template
          fi
        '';

      # Generate complete Conan setup - profiles and home directory setup
      mkConanSetup = {
        config,
        pkgs,
      }: let
        profiles = mkConanProfiles {inherit config pkgs;};
        defaultProfile = config.defaultProfile;
      in {
        # The generated profiles
        inherit profiles;

        # Shell setup script
        setup = ''
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
          ln -sf ${profiles.${defaultProfile}} $CONAN_HOME/profiles/default
          ln -sf ${profiles.release} $CONAN_HOME/profiles/release
          ln -sf ${profiles.debug} $CONAN_HOME/profiles/debug
        '';
      };
    };

    # ============================================================================
    # Package Groups - Templates compose what they need
    # ============================================================================

    # Essential C++ packages - minimum to compile C++
    essential = [
      llvmPkg.clang # Compiler
      llvmPkg.lld # Linker
      llvmPkg.libcxx # C++ standard library
      llvmPkg.libcxx.dev # C++ headers
      pkgs.cmake # Build system
      pkgs.ninja # Build tool
      pkgs.conan # Package manager (architectural choice)
    ];

    # Developer tools - LSPs, formatters, linters, productivity
    devTools = [
      llvmPkg.clang-tools # clangd, clang-format, clang-tidy
      pkgs.cmake-format
      pkgs.cmake-language-server
      pkgs.ccache
      pkgs.pre-commit  # Git hooks for formatting
    ];

    # Debugging tools
    debugging =
      [
        llvmPkg.lldb # LLDB debugger
      ]
      ++ lib.optionals pkgs.stdenv.isLinux [
        pkgs.gdb
        pkgs.valgrind
      ];

    # Static analysis tools
    analysis = with pkgs; [
      cppcheck
      include-what-you-use
    ];

    # Documentation tools
    docs = with pkgs; [
      doxygen
      graphviz
      sphinx
      python3Packages.breathe
      python3Packages.sphinx-rtd-theme
    ];

    # Test frameworks
    testFrameworks = {
      gtest = [pkgs.gtest];
      catch2 = [pkgs.catch2_3];
      doctest = [pkgs.doctest];
    };

    # Performance & benchmarking libraries
    performance = with pkgs; [
      gbenchmark
      boost
      jemalloc
      mimalloc
      tbb
    ];

    # Linux-specific performance tools
    linuxPerf = lib.optionals pkgs.stdenv.isLinux (with pkgs; [
      perf-tools
      liburing
      dpdk
    ]);


    # For backward compatibility / system-wide (uses top-level llvmPkg)
    lsp = [llvmPkg.clang-tools];
    formatters = [
      llvmPkg.clang-tools # clang-format
      pkgs.cmake-format
    ];
  };

  # Python development packages
  python = rec {
    # Function to get Python packages with specific versions
    packages = args: let
      pyVersion = args.pythonVersion or pythonVersion;
      withJupyter = args.withJupyter or true;
      python = selectPython pyVersion;
      # Python with essential packages for Neovim debugging and Jupyter
      pythonWithPackages = python.withPackages (ps:
        with ps; [
          debugpy # Python DAP debugging
          pynvim # Neovim Python host
          jupyter-client # Molten communication with kernels
          ipykernel # Create Python kernels
        ]);
    in
      with pkgs;
        [
          pythonWithPackages # Python with debugging and Jupyter packages
          uv # Fast package manager - handles everything else
          basedpyright # LSP (keep system-level for neovim)
          ruff # Fast Python linter and formatter
        ]
        ++ lib.optionals withJupyter [
          # System packages for Jupyter/Molten visualization
          imagemagick
          poppler-utils
        ];

    # Convenience: default Python packages for system
    default = packages {};

    # Just the LSP for neovim
    lsp = with pkgs; [
      basedpyright
      ruff # Also acts as LSP
    ];

    # Formatters for neovim
    formatters = with pkgs; [
      ruff # Fast formatter (ruff_format, ruff_fix)
    ];

    # Python packages for neovim (installed via pynvim)
    pythonPackages = ps:
      with ps; [
        pynvim
        jupyter-client
        ipykernel
        cairosvg
        pnglatex
        plotly
        kaleido
        pyperclip
        nbformat
        jupytext
      ];
  };

  # LaTeX packages
  latex = rec {
    packages = args: let
      scheme = args.scheme or "medium";
      withPandoc = args.withPandoc or false;
      withGraphics = args.withGraphics or false;
    in
      with pkgs;
        [
          texlab # LSP
          (texlive.combine (
            {inherit (texlive) scheme-basic;}
            // (
              if scheme == "small"
              then {inherit (texlive) scheme-small;}
              else if scheme == "medium"
              then {inherit (texlive) scheme-medium;}
              else if scheme == "full"
              then {inherit (texlive) scheme-full;}
              else {}
            )
          ))
        ]
        ++ lib.optionals withPandoc [
          pandoc
          librsvg
          python3Packages.pandocfilters
        ]
        ++ lib.optionals withGraphics [
          ghostscript
          imagemagick
          inkscape
          gnuplot
          graphviz
          poppler-utils
        ]
        ++ lib.optionals stdenv.isLinux [
          zathura # PDF viewer (Linux only)
        ];

    # Convenience: default LaTeX packages for system
    default = packages {};

    # Just the LSP for neovim
    lsp = with pkgs; [texlab];

    # No formatter for LaTeX (texlab handles it)
    formatters = [];
  };

  # OCaml development packages
  ocaml = rec {
    # Function to get OCaml packages
    packages = args: let
      withTools = args.withTools or false;
    in
      with pkgs;
        [
          ocaml
          opam
          dune_3
          ocamlformat
          ocamlPackages.ocaml-lsp
          ocamlPackages.utop # REPL
        ]
        ++ lib.optionals withTools (with ocamlPackages; [
          merlin
          ocp-indent
        ]);

    # Convenience: default OCaml packages for system
    default = packages {};

    # Just the LSP for neovim
    lsp = with pkgs; [ocamlPackages.ocaml-lsp];

    # Formatters for neovim
    formatters = with pkgs; [ocamlformat];
  };

  # Additional language servers for neovim
  lsp = {
    scripting = with pkgs; [
      lua-language-server
      bash-language-server
      nixd
      yaml-language-server
    ];

    config = with pkgs; [
      taplo # TOML
      nodePackages.vscode-langservers-extracted
    ];

    docs = with pkgs; [
      markdown-oxide # Markdown
      sqls # SQL
    ];

    # All LSPs for system neovim
    all =
      cpp.lsp
      ++ python.lsp
      ++ latex.lsp
      ++ ocaml.lsp
      ++ lsp.scripting
      ++ lsp.config
      ++ lsp.docs;
  };

  # All formatters for system neovim
  formatters = {
    all =
      cpp.formatters
      ++ python.formatters
      ++ latex.formatters
      ++ ocaml.formatters
      ++ (with pkgs; [
        stylua # Lua
        alejandra # Nix
        shfmt # Shell
        nodePackages.prettier # JS/TS/JSON/Markdown/HTML/CSS
        sqlfluff
      ]);
  };

  # Debuggers for system neovim
  debuggers = {
    all =
      [
        llvmPkg.lldb # C/C++ (includes lldb-dap)
        # debugpy is now included in pythonWithEssentials
      ]
      ++ lib.optionals pkgs.stdenv.isLinux (with pkgs; [
        gdb # GNU debugger
        valgrind # Memory checker
        delve # Go debugger
      ]);
  };

  # System CLI tools (replaces lib/shared.nix)
  system = {
    # Core system tools used by all environments
    cli =
      core.essential
      ++ core.search
      ++ core.utils
      ++ (with pkgs; [
        # Shell and terminal
        bash
        zsh-fzf-tab
        tmux
        tmuxp

        # System utilities
        age
        bat
        eza
        fswatch
        fzf
        htop
        mosh
        sops
        zoxide

        # Development tools
        gh
        glow
        go
        lua5_1
        luarocks
        shellcheck
        tree-sitter

        # OCaml package manager (LSP and formatter are in lsp.all and formatters.all)
        opam

        # Project tools (vanilla configs, available for quick prototyping)
        conan
        cmake
        cmake-format
        cmake-language-server
        ninja
        ccache
        bear # For compile_commands.json generation
        gtest # Google Test framework
        pkg-config
        llvmPkg.lldb # LLDB debugger with lldb-dap for DAP support

        # Security
        gnupg

        # Applications
        brave
        chatgpt
        claude-code
        discord-ptb
        obsidian
      ])
      ++ [
        pythonWithEssentials # Python with debugging/Jupyter packages
        pkgs.uv # Python package manager
        pkgs.basedpyright # Python LSP
        pkgs.ruff # Python linter/formatter
        pythonPkg.pkgs.pytest # Python testing framework (matches Python version)
        pkgs.imagemagick # For Jupyter/Molten visualization
        pkgs.poppler-utils # For Jupyter/Molten PDF support
      ]
      ++ latex.lsp # Include texlab
      ++ formatters.all # Include alejandra and other formatters
      ++ lib.optionals pkgs.stdenv.isLinux [
        pkgs.xclip
      ];

    # Platform-specific helpers
    forDarwin = lib.mkIf pkgs.stdenv.isDarwin;
    forLinux = lib.mkIf pkgs.stdenv.isLinux;

    # Platform-specific clipboard command
    clipboardCommand =
      if pkgs.stdenv.isDarwin
      then "pbcopy"
      else if pkgs.stdenv.isLinux
      then "xclip -selection clipboard"
      else "clip"; # Fallback for Windows/WSL
  };

  # Complete package set for system neovim
  neovim = {
    packages =
      core.essential
      ++ core.search
      ++ core.utils
      ++ lsp.all
      ++ formatters.all
      ++ [
        pythonWithEssentials # Python with debugging/Jupyter packages
        pkgs.uv # Python package manager
        pkgs.basedpyright # Python LSP
        pkgs.ruff # Python linter/formatter
        pkgs.imagemagick # For Jupyter/Molten visualization
        pkgs.poppler-utils # For Jupyter/Molten PDF support
        pkgs.nodejs # Node.js runtime for copilot.lua
      ];

    pythonPackages = python.pythonPackages;
  };
}
