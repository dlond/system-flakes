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
      env = environments.mkCppEnv {config = flatConfig; inherit pkgs;};
    in
      pkgs.mkShell (env.cmakeEnv // {
        inherit name;
        nativeBuildInputs = packages;

        shellHook = ''
          ${env.conan.setup}
          ${env.preCommitHook}
          ${env.docsSetup}

          echo "${name} Environment"
          echo "================================"
          ${env.configSummary}
          ${lib.optionalString (cfg.performance.enableBenchmarks or false) ''
            echo "  Optimization: -O${toString cfg.essential.optimizationLevel}"
            ${lib.optionalString (cfg.essential.alignForCache or false) ''echo "  Cache Alignment: ON"''}
          ''}
          echo ""
          ${lib.optionalString (cfg.performance.enableBenchmarks or false) env.perfFlagsSummary}
          ${lib.optionalString (cfg.performance.enableBenchmarks or false) ''echo ""''}
          echo "Tools:"
          echo "  Conan: $(conan --version)"
          echo "  CMake: $(cmake --version | head -1)"
          echo "  Clang: $(clang --version | head -1)"
          ${env.ccacheInfo}
          ${env.docsInfo}
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

    # ============================================================================
    # Internal Implementation - Not for template use
    # ============================================================================
    helpers = rec {
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

      # Generate configuration summary for shell
      mkConfigSummary = config: ''
        echo "Configuration (from flake.nix):"
        echo "  C++ Standard: ${toString config.cppStandard}"
        echo "  Default Profile: ${config.defaultProfile}"
        echo "  Testing: ${boolToCMake config.enableTesting} (${config.testFramework})"
        echo "  LTO: ${boolToCMake config.enableLTO}${lib.optionalString config.enableLTO " (${
          if config.useThinLTO
          then "thin"
          else "full"
        })"}"
        echo "  Warnings: ${config.warningLevel}"
        ${lib.optionalString config.enableBenchmarks ''echo "  Benchmarks: ON"''}
        ${lib.optionalString config.marchNative ''echo "  March Native: ON"''}
        ${lib.optionalString (!config.enableExceptions) ''echo "  Exceptions: OFF"''}
        ${lib.optionalString (!config.enableRTTI) ''echo "  RTTI: OFF"''}
      '';

      # Generate performance flags summary (for low-latency template)
      mkPerfFlagsSummary = config: ''
        echo "Performance Flags:"
        echo "  CXXFLAGS: ${mkCxxFlags config}"
        echo "  LDFLAGS: ${mkLdFlags config}"
      '';

      # Generate ccache info for shell
      mkCcacheInfo = config:
        lib.optionalString config.enableCcache ''
          if command -v ccache >/dev/null 2>&1; then
            echo "  ccache: enabled ($(ccache --version | head -1 | cut -d' ' -f3))"
          fi
        '';

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

      # Generate documentation info
      mkDocsInfo = config:
        lib.optionalString config.enableDocs ''
          echo "  Documentation: enabled (Sphinx + Breathe)"
          echo "    Build docs: cmake --build build --target docs"
          echo "    View docs:  open build/docs/html/index.html"
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

    # ============================================================================
    # Environment Builder - Provides essential C++ infrastructure
    # ============================================================================
    environments = {
      # Minimal C++ environment - just essential infrastructure
      mkCppEnv = {
        config,  # Expects complete config (use mkConfigDefaults in template)
        pkgs,
      }: let
        conan = helpers.mkConanSetup {inherit config pkgs;};
      in {
        # Essential C++ infrastructure - always provided
        conan = conan;  # Contains .profiles and .setup
        cmakeEnv = helpers.mkCMakeEnv config;

        # Optional helpers - templates can use or ignore
        configSummary = helpers.mkConfigSummary config;
        ccacheInfo = helpers.mkCcacheInfo config;
        preCommitHook = helpers.mkPreCommitHook config;
        docsInfo = helpers.mkDocsInfo config;
        docsSetup = helpers.mkDocsSetup config;
        perfFlagsSummary = helpers.mkPerfFlagsSummary config;
      };
    };

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
