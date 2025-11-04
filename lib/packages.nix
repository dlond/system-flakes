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

  selectPython = version:
    if version == "3.10"
    then pkgs.python310
    else if version == "3.11"
    then pkgs.python311
    else if version == "3.12"
    then pkgs.python312
    else if version == "3.13"
    then pkgs.python313
    else if version == "3.14"
    then pkgs.python314
    else throw "Unsupported Python version: ${version}. Available: 3.10, 3.11, 3.12, 3.13, 3.14";

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
    # Shared Configuration Helpers - Used by all C++ templates
    # ============================================================================
    helpers = rec {
      # Convert boolean to cmake ON/OFF string
      boolToCMake = b:
        if b
        then "ON"
        else "OFF";

      # Generate CXXFLAGS from config
      mkCxxFlags = config:
        lib.concatStringsSep " " (
          ["-O${toString (config.optimizationLevel or 2)}"]
          ++ lib.optionals (config.marchNative or false) ["-march=native" "-mtune=native"]
          ++ lib.optionals (config.enableLTO or false) [
            (
              if config.useThinLTO or false
              then "-flto=thin"
              else "-flto"
            )
          ]
          ++ lib.optionals (!(config.enableExceptions or true)) ["-fno-exceptions"]
          ++ lib.optionals (!(config.enableRTTI or true)) ["-fno-rtti"]
          ++ lib.optionals (config.enableFastMath or false) ["-ffast-math"]
          ++ lib.optionals (config.alignForCache or false) ["-falign-functions=64"]
        );

      # Generate LDFLAGS from config
      mkLdFlags = config:
        lib.concatStringsSep " " (
          ["-fuse-ld=lld"]
          ++ lib.optionals (config.enableLTO or false) [
            (
              if config.useThinLTO or false
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
      }:
        let
          # Apply debug overrides if variant is debug
          finalConfig =
            if variant == "debug" then
              config // {
                buildType = "Debug";
                optimizationLevel = "0";
                enableSanitizers = true;
                marchNative = false;
              }
            else
              config;
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
      mkCMakeEnv = config: {
        CMAKE_CXX_STANDARD = toString (config.cppStandard or 20);
        CMAKE_BUILD_TYPE = config.buildType or "Release";
        BUILD_SHARED_LIBS = boolToCMake (config.buildSharedLibs or false);
        ENABLE_LTO = boolToCMake (config.enableLTO or false);
        USE_THIN_LTO = boolToCMake (config.useThinLTO or false);
        ENABLE_EXCEPTIONS = boolToCMake (config.enableExceptions or true);
        ENABLE_RTTI = boolToCMake (config.enableRTTI or true);
        ENABLE_TESTING = boolToCMake (config.enableTesting or true);
        TEST_FRAMEWORK = config.testFramework or "gtest";
        ENABLE_BENCHMARKS = boolToCMake (config.enableBenchmarks or false);
        ENABLE_COVERAGE = boolToCMake (config.enableCoverage or false);
        ENABLE_SANITIZERS = boolToCMake (config.enableSanitizers or false);
        ENABLE_CLANG_TIDY = boolToCMake (config.enableClangTidy or false);
        ENABLE_CPPCHECK = boolToCMake (config.enableCppCheck or false);
        ENABLE_IWYU = boolToCMake (config.enableIncludeWhatYouUse or false);
        ENABLE_DOCS = boolToCMake (config.enableDocs or false);
        OPTIMIZATION_LEVEL = toString (config.optimizationLevel or 2);
        MARCH_NATIVE = boolToCMake (config.marchNative or false);
        ENABLE_FAST_MATH = boolToCMake (config.enableFastMath or false);
        ALIGN_FOR_CACHE = boolToCMake (config.alignForCache or false);
        WARNING_LEVEL = config.warningLevel or "all";
        CMAKE_EXPORT_COMPILE_COMMANDS = boolToCMake (config.generateCompileCommands or true);
      } // lib.optionalAttrs (config.enableCcache or true) {
        CCACHE_DIR = "$HOME/.ccache";
        CCACHE_MAXSIZE = config.ccacheMaxSize or "5G";
      };

      # Generate configuration summary for shell
      mkConfigSummary = config: ''
        echo "Configuration (from flake.nix):"
        echo "  C++ Standard: ${toString (config.cppStandard or 20)}"
        echo "  Build Type: ${config.buildType or "Release"}"
        echo "  Testing: ${boolToCMake (config.enableTesting or true)} (${config.testFramework or "gtest"})"
        echo "  LTO: ${boolToCMake (config.enableLTO or false)}${lib.optionalString (config.enableLTO or false) " (${
          if config.useThinLTO or false
          then "thin"
          else "full"
        })"}"
        echo "  Warnings: ${config.warningLevel or "all"}"
        ${lib.optionalString (config.enableBenchmarks or false) ''echo "  Benchmarks: ON"''}
        ${lib.optionalString (config.marchNative or false) ''echo "  March Native: ON"''}
        ${lib.optionalString (!(config.enableExceptions or true)) ''echo "  Exceptions: OFF"''}
        ${lib.optionalString (!(config.enableRTTI or true)) ''echo "  RTTI: OFF"''}
      '';

      # Generate performance flags summary (for low-latency template)
      mkPerfFlagsSummary = config: ''
        echo "Performance Flags:"
        echo "  CXXFLAGS: ${mkCxxFlags config}"
        echo "  LDFLAGS: ${mkLdFlags config}"
      '';

      # Generate ccache info for shell
      mkCcacheInfo = config:
        lib.optionalString (config.enableCcache or true) ''
          if command -v ccache >/dev/null 2>&1; then
            echo "  ccache: enabled ($(ccache --version | head -1 | cut -d' ' -f3))"
          fi
        '';

      # Generate pre-commit hook installation
      mkPreCommitHook = config:
        lib.optionalString (config.enablePreCommitHooks or false) ''
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
        lib.optionalString (config.enableDocs or false) ''
          echo "  Documentation: enabled (Sphinx + Breathe)"
          echo "    Build docs: cmake --build build --target docs"
          echo "    View docs:  open build/docs/html/index.html"
        '';

      # Generate documentation setup helper
      mkDocsSetup = config:
        lib.optionalString (config.enableDocs or false) ''
          # Create docs structure if it doesn't exist
          if [ ! -f docs/conf.py ] && [ -f CMakeLists.txt ]; then
            echo "Setting up documentation structure..."
            mkdir -p docs
            # We'll populate these files in the template
          fi
        '';
    };

    # ============================================================================
    # Template-Specific Package Builders - Return components for flexibility
    # ============================================================================
    environments = {
      # Standard C++ development environment components
      mkStandardEnv = {
        config,
        pkgs,
      }: {
        # Core C++ packages
        packages =
          packages {
            llvmVersion = config.llvmVersion or llvmVersion;
            packageManager = "conan";
            testFramework = config.testFramework or "gtest";
            withAnalysis = config.enableClangTidy or false;
            withDocs = config.enableDocs or false;
          }
          ++ core.essential ++ core.search
          ++ [pkgs.fd] # For Conan cache symlinking
          ++ lib.optionals (config.enablePreCommitHooks or false) [pkgs.pre-commit]
          ++ lib.optionals (config.enableDocs or false) [
            pkgs.doxygen
            pkgs.graphviz # For Doxygen graphs
            pkgs.sphinx
            pkgs.python3Packages.breathe
            pkgs.python3Packages.sphinx-rtd-theme
          ];

        # Generated artifacts
        profiles = helpers.mkConanProfiles {inherit config pkgs;};
        profile = helpers.mkConanProfile {inherit config pkgs;}; # Keep for backward compat
        cmakeEnv = helpers.mkCMakeEnv config;

        # Helper to generate standard summary (templates can use or ignore)
        configSummary = helpers.mkConfigSummary config;
        ccacheInfo = helpers.mkCcacheInfo config;
        preCommitHook = helpers.mkPreCommitHook config;
        docsInfo = helpers.mkDocsInfo config;
        docsSetup = helpers.mkDocsSetup config;
      };

      # Low-latency/high-performance C++ environment components
      mkLowLatencyEnv = {
        config,
        pkgs,
      }: let
        baseEnv = environments.mkStandardEnv {inherit config pkgs;};

        # Performance-specific packages
        performanceLibs = with pkgs;
          [
            gbenchmark
            boost
            jemalloc
            mimalloc
            tbb
          ]
          ++ lib.optionals (config.additionalTestFrameworks or false) [
            catch2_3
          ];

        # Linux-specific performance tools
        linuxTools = lib.optionals pkgs.stdenv.isLinux (with pkgs;
          [
            perf-tools
            valgrind
            liburing
          ]
          ++ lib.optionals (config.enableDPDK or false) [
            dpdk
          ]);
      in {
        # Combine base packages with performance tools
        packages = baseEnv.packages ++ performanceLibs ++ linuxTools;

        # Inherit generated artifacts
        profiles = baseEnv.profiles;
        profile = baseEnv.profile; # Keep for backward compat
        cmakeEnv = baseEnv.cmakeEnv;

        # Additional helpers for low-latency
        configSummary = baseEnv.configSummary;
        ccacheInfo = baseEnv.ccacheInfo;
        preCommitHook = baseEnv.preCommitHook;
        docsInfo = baseEnv.docsInfo;
        docsSetup = baseEnv.docsSetup;
        perfFlagsSummary = helpers.mkPerfFlagsSummary config;

        # Export the individual package groups (in case template wants them separately)
        packageGroups = {
          base = baseEnv.packages;
          performance = performanceLibs;
          linux = linuxTools;
        };
      };

      # Python + C++ hybrid environment components
      mkHybridEnv = {
        config,
        pkgs,
      }: let
        baseEnv = environments.mkStandardEnv {
          config =
            config
            // {
              # Force C++17 for Python bindings compatibility
              cppStandard = config.cppStandard or "17";
            };
          inherit pkgs;
        };

        # Python environment
        pythonVersion = config.pythonVersion or pythonVersion;
        pythonWithPackages = (selectPython pythonVersion).withPackages (ps:
          with ps; [
            debugpy
            pynvim
            jupyter-client
            ipykernel
            pybind11
            setuptools
            wheel
            build
          ]);

        pythonTools = with pkgs;
          [
            pythonWithPackages
            uv
            basedpyright
            ruff
          ]
          ++ lib.optionals (config.withJupyter or true) [
            imagemagick
            poppler-utils
          ];
      in {
        # Combine C++ and Python packages
        packages = baseEnv.packages ++ pythonTools;

        # Inherit C++ artifacts
        profiles = baseEnv.profiles;
        profile = baseEnv.profile; # Keep for backward compat
        cmakeEnv =
          baseEnv.cmakeEnv
          // {
            Python3_EXECUTABLE = "${pythonWithPackages}/bin/python";
          };

        # Export components separately for flexibility
        packageGroups = {
          cpp = baseEnv.packages;
          python = pythonTools;
        };

        # Additional environment variables for Python
        pythonEnv = {
          UV_PROJECT_ENVIRONMENT = ".venv";
          Python3_EXECUTABLE = "${pythonWithPackages}/bin/python";
        };

        configSummary = baseEnv.configSummary;
        ccacheInfo = baseEnv.ccacheInfo;
      };
    };

    # Function to get C++ packages with specific versions
    packages = args: let
      llvmVer = args.llvmVersion or llvmVersion;
      packageManager = args.packageManager or "conan";
      testFramework = args.testFramework or "gtest";
      withBazel = args.withBazel or false;
      withDocs = args.withDocs or false;
      withAnalysis = args.withAnalysis or false;
      llvm = selectLLVM llvmVer;

      # Core compiler toolchain
      compiler = [
        llvm.clang
        llvm.clang-tools # clangd, clang-format, clang-tidy
        llvm.lld
        llvm.lldb # Includes lldb-dap
        llvm.libcxx
        llvm.libcxx.dev
      ];

      # Build tools (always included)
      buildTools = with pkgs; [
        cmake
        cmake-format
        cmake-language-server
        ninja
        ccache
        bear # For compile_commands.json generation
      ];

      # Package managers
      packageManagers = {
        conan = [pkgs.conan];
        vcpkg = [pkgs.vcpkg];
        cpm = []; # CPM is CMake-native
        none = [];
      };

      # Testing frameworks
      testFrameworks = {
        gtest = [pkgs.gtest];
        catch2 = [pkgs.catch2_3];
        doctest = [pkgs.doctest];
        boost = [pkgs.boost];
        none = [];
      };

      # Optional tools
      bazelTools = lib.optionals withBazel (with pkgs; [
        bazel
        bazel-buildtools
        buildifier
      ]);

      docsTools = lib.optionals withDocs (with pkgs; [
        doxygen
        graphviz
      ]);

      analysisTools = lib.optionals withAnalysis (with pkgs;
        [
          cppcheck
          include-what-you-use
          clang-analyzer
        ]
        ++ lib.optionals stdenv.isLinux [
          gdb
          valgrind
        ]);
    in
      compiler
      ++ buildTools
      ++ (packageManagers.${packageManager} or packageManagers.conan)
      ++ (testFrameworks.${testFramework} or testFrameworks.gtest)
      ++ bazelTools
      ++ docsTools
      ++ analysisTools;

    # Convenience: default C++ packages for system
    default = packages {};

    # Just the LSP for neovim
    lsp = [llvmPkg.clang-tools];

    # Just the formatter for neovim
    formatters = with pkgs; [
      llvmPkg.clang-tools # clang-format
      cmake-format
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
