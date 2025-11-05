# Single source of truth for all packages across system and dev shells
# System uses defaults, dev-shells can override versions
{
  pkgs,
  # Global LLVM version default - templates can override via config.essential.llvmVersion
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
      config ? {}, # User config (partial)
      name ? "cpp-dev", # Optional shell name
      extraPackages ? [], # Optional extra packages
    }: let
      # Apply defaults to get complete config
      # Manual merge enforces structure - templates must follow defaults structure
      defaults = helpers.mkConfigDefaults {};
      finalConfig = {
        cpp = {
          essential =
            defaults.cpp.essential
            // (config.cpp.essential or {})
            // {
              debug = defaults.cpp.essential.debug // (config.cpp.essential.debug or {});
              release = defaults.cpp.essential.release // (config.cpp.essential.release or {});
            };
          devTools = defaults.cpp.devTools // (config.cpp.devTools or {});
          testing =
            defaults.cpp.testing
            // (config.cpp.testing or {})
            // {
              debug = defaults.cpp.testing.debug // (config.cpp.testing.debug or {});
              release = defaults.cpp.testing.release // (config.cpp.testing.release or {});
            };
          performance = defaults.cpp.performance // (config.cpp.performance or {});
          linuxPerf = defaults.cpp.linuxPerf // (config.cpp.linuxPerf or {});
          analysis = defaults.cpp.analysis // (config.cpp.analysis or {});
          docs = defaults.cpp.docs // (config.cpp.docs or {});
        };
      };
      cfg = finalConfig.cpp; # Shorthand

      # Compose packages based on config
      packages =
        essential
        ++ core.essential
        ++ core.search
        ++ lib.optionals cfg.devTools.enable devTools
        ++ lib.optionals cfg.devTools.enableCcache [pkgs.ccache]
        ++ lib.optionals cfg.devTools.enablePreCommitHooks [pkgs.pre-commit]
        ++ lib.optionals cfg.analysis.enable analysis
        ++ lib.optionals cfg.docs.enable docs
        ++ lib.optionals cfg.testing.enable testFrameworks.${cfg.testing.testFramework}
        ++ lib.optionals cfg.performance.enable performance
        ++ lib.optionals cfg.linuxPerf.enable linuxPerf # linuxPerf already checks isLinux
        ++ extraPackages;

      # Get environment setup (pass nested config)
      conan = helpers.mkConanSetup {
        config = cfg;
        inherit pkgs;
      };
      cmakeEnv = helpers.mkCMakeEnv cfg;
      preCommitHook = helpers.mkPreCommitHook cfg;
      docsSetup = helpers.mkDocsSetup cfg;

      # Generate README content
      readmeContent = helpers.mkReadme {
        inherit name cfg;
      };
    in
      pkgs.mkShell (cmakeEnv
        // {
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
      # Access structure directly - no intermediate variables
      mkReadme = {
        name,
        cfg,
      }: let
        defaultVariant = cfg.essential.defaultProfile;
      in ''
        # ${name}

        ${
          if cfg.performance.enable
          then "High-performance C++ development environment optimized for low-latency systems."
          else "Modern C++ development environment with Conan package management and CMake build system."
        }

        ## Features

        ${
          if cfg.performance.enable
          then ''            - ⚡ **Maximum Performance** - Aggressive optimizations enabled
            - 🚀 **C++${toString cfg.essential.cppStandard}** - Latest language features
            ${
              if cfg.essential.${defaultVariant}.enableLTO
              then
                "- 🔥 **LTO** - Link-time optimization enabled"
                + (
                  if cfg.essential.${defaultVariant}.useThinLTO
                  then " (ThinLTO)"
                  else ""
                )
                + "\n"
              else ""
            }${
              if cfg.essential.${defaultVariant}.marchNative
              then "- 🎯 **CPU-Specific** - Native architecture targeting\n"
              else ""
            }${
              if cfg.performance.enableBenchmarks
              then "- 📊 **Benchmarking** - Performance measurement tools\n"
              else ""
            }${
              if cfg.essential.${defaultVariant}.alignForCache
              then "- 💾 **Cache Alignment** - Optimized for cache lines\n"
              else ""
            }${
              if cfg.linuxPerf.enable
              then "- 🐧 **Linux Perf Tools** - Advanced profiling capabilities\n"
              else ""
            }''
          else ''            - 🚀 **C++${toString cfg.essential.cppStandard}** - Modern C++ standard
            - 📦 **Conan 2** - Package management
            - 🔧 **CMake Presets** - Consistent build configuration
            - 🛠️ **LLVM Toolchain** - Latest compiler
            ${
              if cfg.devTools.enableClangTidy
              then "- 🔍 **clang-tidy** - Static analysis\n"
              else ""
            }${
              if cfg.devTools.enableCcache
              then "- ⚡ **ccache** - Build acceleration\n"
              else ""
            }${
              if cfg.testing.enable
              then "- 🧪 **Testing** - " + cfg.testing.testFramework + " framework\n"
              else ""
            }''
        }

        ## Configuration

        ### Configuration Options

        All available configuration options with defaults and explanations:

        | Option | Default | Description | Current |
        |--------|---------|-------------|---------|
        | **cpp.essential** | | *Core compilation settings* | |
        | \`cppStandard\` | \`20\` | C++ standard version (17, 20, 23) | **${toString cfg.essential.cppStandard}** |
        | \`defaultProfile\` | \`"release"\` | Default Conan profile | ${cfg.essential.defaultProfile} |
        | \`enableLTO\` | \`false\` | Link-time optimization | ${
          if cfg.essential.${defaultVariant}.enableLTO
          then "**true**"
          else "false"
        } |
        | \`useThinLTO\` | \`false\` | Use ThinLTO (faster than full LTO) | ${
          if cfg.essential.${defaultVariant}.useThinLTO
          then "**true**"
          else "false"
        } |
        | \`enableExceptions\` | \`true\` | C++ exception handling | ${
          if cfg.essential.enableExceptions
          then "true"
          else "**false**"
        } |
        | \`enableRTTI\` | \`true\` | Runtime type information | ${
          if cfg.essential.enableRTTI
          then "true"
          else "**false**"
        } |
        | \`optimizationLevel\` | \`2\` | Optimization (-O0 to -O3, s, z) | ${
          if (toString cfg.essential.${defaultVariant}.optimizationLevel) != "2"
          then "**" + (toString cfg.essential.${defaultVariant}.optimizationLevel) + "**"
          else "2"
        } |
        | \`marchNative\` | \`false\` | CPU-specific optimizations | ${
          if cfg.essential.${defaultVariant}.marchNative
          then "**true**"
          else "false"
        } |
        | \`alignForCache\` | \`false\` | Cache-line alignment (64 bytes) | ${
          if cfg.essential.${defaultVariant}.alignForCache
          then "**true**"
          else "false"
        } |
        | \`warningLevel\` | \`"all"\` | Compiler warnings (none/default/all/extra) | ${cfg.essential.warningLevel} |
        | **cpp.devTools** | | *Development productivity tools* | |
        | \`enable\` | \`true\` | Include dev tools | ${
          if cfg.devTools.enable
          then "true"
          else "**false**"
        } |
        | \`enableClangTidy\` | \`false\` | Static analysis linting | ${
          if cfg.devTools.enableClangTidy
          then "**true**"
          else "false"
        } |
        | \`enableCcache\` | \`true\` | Build caching | ${
          if cfg.devTools.enableCcache
          then "true"
          else "**false**"
        } |
        | \`ccacheMaxSize\` | \`"5G"\` | Cache size limit | ${cfg.devTools.ccacheMaxSize} |
        | \`enablePreCommitHooks\` | \`false\` | Git pre-commit hooks | ${
          if cfg.devTools.enablePreCommitHooks
          then "**true**"
          else "false"
        } |
        | **cpp.analysis** | | *Static analysis tools* | |
        | \`enable\` | \`false\` | Include analysis tools | ${
          if cfg.analysis.enable
          then "**true**"
          else "false"
        } |
        | \`enableCppCheck\` | \`false\` | CppCheck analysis | ${
          if cfg.analysis.enableCppCheck
          then "**true**"
          else "false"
        } |
        | \`enableIncludeWhatYouUse\` | \`false\` | Include-what-you-use | ${
          if cfg.analysis.enableIncludeWhatYouUse
          then "**true**"
          else "false"
        } |
        | **cpp.testing** | | *Testing framework configuration* | |
        | \`enable\` | \`true\` | Include test framework | ${
          if cfg.testing.enable
          then "true"
          else "**false**"
        } |
        | \`testFramework\` | \`"gtest"\` | Framework (gtest/catch2/doctest) | ${cfg.testing.testFramework} |
        | \`enableCoverage\` | \`false\` | Code coverage reporting | ${
          if cfg.testing.${defaultVariant}.enableCoverage
          then "**true**"
          else "false"
        } |
        | \`enableSanitizers\` | \`false\` | Memory/UB sanitizers (debug) | ${
          if cfg.testing.${defaultVariant}.enableSanitizers
          then "**true**"
          else "false"
        } |
        | **cpp.performance** | | *Performance optimization tools* | |
        | \`enable\` | \`false\` | Include performance libraries | ${
          if cfg.performance.enable
          then "**true**"
          else "false"
        } |
        | \`enableBenchmarks\` | \`false\` | Google Benchmark library | ${
          if cfg.performance.enableBenchmarks
          then "**true**"
          else "false"
        } |
        | **cpp.linuxPerf** | | *Linux-specific performance tools* | |
        | \`enable\` | \`false\` | DPDK, perf-tools, io_uring | ${
          if cfg.linuxPerf.enable
          then "**true**"
          else "false"
        } |
        | **cpp.docs** | | *Documentation generation* | |
        | \`enable\` | \`false\` | Include doc tools | ${
          if cfg.docs.enable
          then "**true**"
          else "false"
        } |
        | \`enableDocs\` | \`false\` | Doxygen + Sphinx | ${
          if cfg.docs.enableDocs
          then "**true**"
          else "false"
        } |

        **Bold** values indicate overrides from defaults.

        ### Current Configuration

        Settings from \`flake.nix\`:

        \`\`\`nix
        config = {
          cpp.essential = {
            cppStandard = ${toString cfg.essential.cppStandard};${
          if cfg.performance.enable
          then ''
            enableLTO = ${
              if cfg.essential.${defaultVariant}.enableLTO
              then "true"
              else "false"
            };${
              if cfg.essential.${defaultVariant}.useThinLTO
              then ''
                useThinLTO = true;''
              else ""
            }
            enableExceptions = ${
              if cfg.essential.enableExceptions
              then "true"
              else "false"
            };
            enableRTTI = ${
              if cfg.essential.enableRTTI
              then "true"
              else "false"
            };
            optimizationLevel = ${toString cfg.essential.${defaultVariant}.optimizationLevel};${
              if cfg.essential.${defaultVariant}.marchNative
              then ''
                marchNative = true;''
              else ""
            }${
              if cfg.essential.${defaultVariant}.alignForCache
              then ''
                alignForCache = true;''
              else ""
            }''
          else ""
        }
          };${
          if cfg.devTools.enableClangTidy
          then ''
            cpp.devTools = {
              enableClangTidy = true;
            };''
          else ""
        }${
          if cfg.performance.enableBenchmarks
          then ''
            cpp.performance = {
              enable = true;
              enableBenchmarks = true;
            };''
          else ""
        }${
          if cfg.linuxPerf.enable
          then ''
            cpp.linuxPerf = {
              enable = true;
            };''
          else ""
        }
        };
        \`\`\`

        ## Compiler Flags

        **Release Build:**
        - \`-O${toString cfg.essential.${defaultVariant}.optimizationLevel}\` - Optimization level
        ${
          if cfg.essential.${defaultVariant}.marchNative
          then "- `-march=native -mtune=native` - CPU-specific instructions\n"
          else ""
        }${
          if cfg.essential.${defaultVariant}.enableLTO
          then
            "- `-flto"
            + (
              if cfg.essential.${defaultVariant}.useThinLTO
              then "=thin"
              else ""
            )
            + "` - Link-time optimization\n"
          else ""
        }${
          if !cfg.essential.enableExceptions
          then "- `-fno-exceptions` - No exception handling\n"
          else ""
        }${
          if !cfg.essential.enableRTTI
          then "- `-fno-rtti` - No RTTI overhead\n"
          else ""
        }${
          if cfg.essential.${defaultVariant}.alignForCache
          then "- `-falign-functions=64` - Cache-line alignment\n"
          else ""
        }

        **Debug Build:**
        - \`-O0 -g3\` - No optimization, full debug info
        ${
          if cfg.testing.debug.enableSanitizers
          then "- `-fsanitize=address,undefined` - Memory and UB detection\n"
          else ""
        }

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
        ${
          if cfg.testing.enable
          then "├── tests/                 # Unit tests\n"
          else ""
        }${
          if cfg.performance.enableBenchmarks
          then "├── bench/                 # Benchmarks\n"
          else ""
        }└── build/                 # Build output (git-ignored)
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
        ${
          if cfg.devTools.enableClangTidy
          then "- **Static Analysis**: clang-tidy\n"
          else ""
        }${
          if cfg.analysis.enableCppCheck
          then "- **Static Analysis**: cppcheck\n"
          else ""
        }${
          if cfg.devTools.enableCcache
          then "- **Cache**: ccache\n"
          else ""
        }${
          if cfg.testing.enable
          then "- **Testing**: " + cfg.testing.testFramework + "\n"
          else ""
        }${
          if cfg.performance.enableBenchmarks
          then "- **Benchmarking**: Google Benchmark\n"
          else ""
        }${
          if cfg.docs.enableDocs
          then "- **Documentation**: Doxygen + Sphinx\n"
          else ""
        }

        ## Development Tips

        1. **IDE Integration**: The environment generates \`compile_commands.json\` for clangd support
        2. **Clean Build**: \`rm -rf build/ && conan install . --profile=release --build=missing\`
        3. **Switch Profiles**: Use \`--preset=conan-debug\` or \`--preset=conan-release\`
        ${
          if cfg.devTools.enableCcache
          then "4. **Faster Builds**: ccache enabled - subsequent builds will be faster\n"
          else ""
        }${
          if cfg.performance.enableBenchmarks
          then ''
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
          ''
          else ""
        }

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
            # Non-variant options (same for debug/release)
            cppStandard = 20;
            defaultProfile = "release";
            compiler = "clang";
            llvmVersion = llvmVersion; # Use the input parameter
            buildJobs = 12;
            warningLevel = "all";
            enableExceptions = true;
            enableRTTI = true;

            # Variant-specific defaults
            debug = {
              optimizationLevel = 0; # No optimization for better debugging
              enableLTO = false;
              useThinLTO = false;
              marchNative = false;
              alignForCache = false;
              enableFastMath = false;
            };

            release = {
              optimizationLevel = 2; # Standard release optimization
              enableLTO = false; # Templates can enable for performance
              useThinLTO = false;
              marchNative = false; # Templates can enable for performance
              alignForCache = false; # Templates can enable for performance
              enableFastMath = false; # Templates can enable for performance
            };
          };

          # Development tools - conditionally included
          devTools = {
            enable = true; # Include by default
            enablePreCommitHooks = false;
            enableCcache = true;
            ccacheMaxSize = "5G";
            enableClangTidy = false; # These enable checks, don't add packages
          };

          # Static analysis - conditionally included
          analysis = {
            enable = false; # Off by default
            enableCppCheck = false;
            enableIncludeWhatYouUse = false;
          };

          # Documentation - conditionally included
          docs = {
            enable = false; # Off by default
            enableDocs = false;
          };

          # Testing - conditionally included
          testing = {
            # Non-variant options
            enable = true; # Include by default
            testFramework = "gtest"; # gtest, catch2, doctest

            # Variant-specific defaults
            debug = {
              enableSanitizers = true; # Catch memory issues in debug builds
              enableCoverage = true; # Enable coverage in debug builds
            };

            release = {
              enableSanitizers = false; # No overhead in release
              enableCoverage = false; # No coverage in release
            };
          };

          # Performance & benchmarking - conditionally included
          performance = {
            enable = false; # Off by default
            enableBenchmarks = false;
          };

          # Linux performance - conditionally included (Linux only)
          linuxPerf = {
            enable = false; # Off by default
            enableDPDK = false;
          };
        };
      };

      # Convert boolean to cmake ON/OFF string
      boolToCMake = b:
        if b
        then "ON"
        else "OFF";

      # Generate CXXFLAGS from config structure - access directly
      mkCxxFlags = config: variant:
        lib.concatStringsSep " " (
          ["-O${toString config.essential.${variant}.optimizationLevel}"]
          ++ lib.optionals config.essential.${variant}.marchNative ["-march=native" "-mtune=native"]
          ++ lib.optionals config.essential.${variant}.enableLTO [
            (
              if config.essential.${variant}.useThinLTO
              then "-flto=thin"
              else "-flto"
            )
          ]
          ++ lib.optionals (!config.essential.enableExceptions) ["-fno-exceptions"]
          ++ lib.optionals (!config.essential.enableRTTI) ["-fno-rtti"]
          ++ lib.optionals config.essential.${variant}.enableFastMath ["-ffast-math"]
          ++ lib.optionals config.essential.${variant}.alignForCache ["-falign-functions=64"]
        );

      # Generate LDFLAGS from config structure - access directly
      mkLdFlags = config: variant:
        lib.concatStringsSep " " (
          ["-fuse-ld=lld"]
          ++ lib.optionals config.essential.${variant}.enableLTO [
            (
              if config.essential.${variant}.useThinLTO
              then "-flto=thin"
              else "-flto"
            )
          ]
        );

      # Generate Conan profile from config - access structure directly
      mkConanProfile = {
        config,
        pkgs,
        variant ? "release",
      }: let
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
          compiler=${config.essential.compiler}
          compiler.version=${toString config.essential.llvmVersion}
          compiler.libcxx=${
            if config.essential.compiler == "clang"
            then "libc++"
            else "libstdc++11"
          }
          compiler.cppstd=${toString config.essential.cppStandard}
          build_type=${buildType}

          [conf]
          tools.cmake.cmaketoolchain:generator=Ninja
          tools.build:jobs=${toString config.essential.buildJobs}
          ${lib.optionalString config.devTools.enableCcache ''
            tools.cmake.cmaketoolchain:extra_variables={"CMAKE_C_COMPILER_LAUNCHER": "${pkgs.ccache}/bin/ccache", "CMAKE_CXX_COMPILER_LAUNCHER": "${pkgs.ccache}/bin/ccache"}
          ''}

          [buildenv]
          CXXFLAGS=${mkCxxFlags config variant}
          LDFLAGS=${mkLdFlags config variant}
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
      # Note: Variant-specific flags (optimization, LTO, etc.) are handled by Conan profiles
      mkCMakeEnv = cfg:
        {
          # Essential build configuration (non-variant)
          CMAKE_CXX_STANDARD = toString cfg.essential.cppStandard;
          CMAKE_EXPORT_COMPILE_COMMANDS = "ON"; # Always generate for LSP

          # C++ feature flags (non-variant, apply to both debug and release)
          ENABLE_EXCEPTIONS = boolToCMake cfg.essential.enableExceptions;
          ENABLE_RTTI = boolToCMake cfg.essential.enableRTTI;
          WARNING_LEVEL = cfg.essential.warningLevel;

          # Testing framework configuration (non-variant)
          ENABLE_TESTING = boolToCMake cfg.testing.enable;
          TEST_FRAMEWORK = cfg.testing.testFramework;
          ENABLE_BENCHMARKS = boolToCMake cfg.performance.enableBenchmarks;

          # Development tools (non-variant)
          ENABLE_CLANG_TIDY = boolToCMake cfg.devTools.enableClangTidy;
          ENABLE_CPPCHECK = boolToCMake cfg.analysis.enableCppCheck;
          ENABLE_IWYU = boolToCMake cfg.analysis.enableIncludeWhatYouUse;
          ENABLE_DOCS = boolToCMake cfg.docs.enableDocs;
        }
        // lib.optionalAttrs cfg.devTools.enableCcache {
          CCACHE_DIR = "$HOME/.ccache";
          CCACHE_MAXSIZE = cfg.devTools.ccacheMaxSize;
        };

      # Generate pre-commit hook installation
      mkPreCommitHook = cfg:
        lib.optionalString cfg.devTools.enablePreCommitHooks ''
          # Install pre-commit hooks if config exists
          if [ -f .pre-commit-config.yaml ] && command -v pre-commit >/dev/null 2>&1; then
            if [ ! -f .git/hooks/pre-commit ]; then
              echo "Installing pre-commit hooks..."
              pre-commit install --install-hooks >/dev/null 2>&1 || true
            fi
          fi
        '';

      # Generate documentation setup helper
      mkDocsSetup = cfg:
        lib.optionalString cfg.docs.enableDocs ''
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
        defaultProfile = config.essential.defaultProfile;
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

    # Essential C++ packages - minimum to compile and debug C++
    essential =
      [
        llvmPkg.clang # Compiler
        llvmPkg.lld # Linker
        llvmPkg.libcxx # C++ standard library
        llvmPkg.libcxx.dev # C++ headers
        pkgs.cmake # Build system
        pkgs.ninja # Build tool
        pkgs.conan # Package manager (architectural choice)
        llvmPkg.lldb # LLDB debugger
      ]
      ++ lib.optionals pkgs.stdenv.isLinux [
        pkgs.gdb
        pkgs.valgrind
      ];

    # Developer tools - LSPs, formatters, linters, productivity
    devTools = [
      llvmPkg.clang-tools # clangd, clang-format, clang-tidy
      pkgs.cmake-format
      pkgs.cmake-language-server
      pkgs.ccache
      pkgs.pre-commit # Git hooks for formatting
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
      withJupyter = args.withJupyter or true; # This is OK - args is function parameter
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
      statix
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
