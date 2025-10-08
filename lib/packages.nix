# Single source of truth for all packages across system and dev shells
# System uses defaults, dev-shells can override versions
{
  pkgs,
  # Global version defaults (can be overridden per-language or in dev-shells)
  llvmVersion ? "20", # System default: LLVM 20
  pythonVersion ? "3.11", # System default: Python 3.11
  nodeVersion ? "lts", # System default: Node LTS
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

  selectNode = version:
    if version == "lts" || version == "22"
    then pkgs.nodejs_22
    else if version == "18"
    then pkgs.nodejs_18
    else if version == "20"
    then pkgs.nodejs_20
    else if version == "latest"
    then pkgs.nodejs_latest
    else pkgs.nodejs;

  # Default package selections
  llvmPkg = selectLLVM llvmVersion;
  pythonPkg = selectPython pythonVersion;
  nodePkg = selectNode nodeVersion;
in rec {
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
    # Function to get C++ packages with specific versions
    packages = args: let
      llvmVer = args.llvmVersion or llvmVersion;
      cppStandard = args.cppStandard or "20";
      packageManager = args.packageManager or "conan";
      testFramework = args.testFramework or "gtest";
      withBazel = args.withBazel or false;
      withDocs = args.withDocs or false;
      withAnalysis = args.withAnalysis or false;
      llvm = selectLLVM llvmVer;

      # Core compiler toolchain
      compiler =
        [
          llvm.clang
          llvm.clang-tools # clangd, clang-format, clang-tidy
          llvm.lld
          llvm.lldb
          llvm.libcxx
          llvm.libcxx.dev
        ]
        ++ lib.optionals pkgs.stdenv.isDarwin [
          # lldb-dap is included in lldb on macOS
        ]
        ++ lib.optionals pkgs.stdenv.isLinux [
          pkgs.lldb # Includes lldb-dap on Linux
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
    in
      with pkgs;
        [
          python
          uv # Fast package manager - handles everything else
          basedpyright # LSP (keep system-level for neovim)
          ruff # Fast Python linter and formatter
        ]
        ++ lib.optionals withJupyter [
          # System packages for Jupyter/Molten visualization
          imagemagick
          poppler_utils
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

  # Rust development packages
  rust = rec {
    packages = args: let
      withWasm = args.withWasm or false;
      withTauri = args.withTauri or false;
      withDatabase = args.withDatabase or false;
    in
      with pkgs;
        [
          # Core Rust tools
          cargo-watch
          cargo-edit
          cargo-outdated
          cargo-audit
          cargo-expand
          cargo-generate
          rustfmt
          rust-analyzer
          pkg-config
          openssl
        ]
        ++ lib.optionals withWasm [
          wasm-pack
          wasm-bindgen-cli
          trunk
        ]
        ++ lib.optionals withTauri [
          cargo-tauri
          nodePackages.pnpm
          webkit2gtk
          libsoup
        ]
        ++ lib.optionals withDatabase [
          sqlx-cli
          diesel-cli
          postgresql
          sqlite
        ];

    # Convenience: default Rust packages for system
    default = packages {};

    # Just the LSP for neovim
    lsp = with pkgs; [rust-analyzer];

    # Just the formatter for neovim
    formatters = with pkgs; [rustfmt];
  };

  # Web development packages
  web = rec {
    packages = args: let
      nodeVer = args.nodeVersion or nodeVersion;
      node = selectNode nodeVer;
    in
      [
        node
      ]
      ++ (with pkgs; [
        nodePackages.npm
        nodePackages.yarn
        nodePackages.pnpm
        bun
        nodePackages.typescript
        nodePackages.typescript-language-server
        nodePackages.vscode-langservers-extracted # HTML, CSS, JSON, ESLint
        tailwindcss-language-server
        nodePackages.prettier
      ]);

    # Convenience: default web packages for system
    default = packages {};

    # Just the LSP for neovim
    lsp = with pkgs; [
      nodePackages.typescript-language-server
      nodePackages.vscode-langservers-extracted
      tailwindcss-language-server
    ];

    # Just the formatter for neovim
    formatters = with pkgs; [
      nodePackages.prettier
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
          poppler_utils
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
    ];

    docs = with pkgs; [
      marksman # Markdown
    ];

    # All LSPs for system neovim
    all =
      cpp.lsp
      ++ python.lsp
      ++ rust.lsp
      ++ web.lsp
      ++ latex.lsp
      ++ lsp.scripting
      ++ lsp.config
      ++ lsp.docs;
  };

  # All formatters for system neovim
  formatters = {
    all =
      cpp.formatters
      ++ python.formatters
      ++ rust.formatters
      ++ web.formatters
      ++ latex.formatters
      ++ (with pkgs; [
        stylua # Lua
        alejandra # Nix
        shfmt # Shell
      ]);
  };

  # Debuggers for system neovim
  debuggers = {
    all =
      [
        llvmPkg.lldb # C/C++, Rust (includes lldb-dap)
        pythonPkg.pkgs.debugpy # Python
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
        zsh-vi-mode
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

        # Git tools
        delta
        git-filter-repo

        # Development tools
        gh
        glow
        go
        lua5_1
        luarocks
        shellcheck
        tree-sitter

        # Security
        gnupg

        # Applications
        brave
        chatgpt
        claude-code
        discord-ptb
        # firefox  # Removed - takes too long to build
        obsidian
      ])
      ++ python.default # Include Python for Molten/Jupyter support
      ++ web.default # Include Node.js 20 and web tools
      ++ rust.default # Include rustup
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
      ++ python.default; # For Molten support (includes Jupyter)
    # Note: debuggers are conditionally added in neovim.nix based on withDebugger option

    pythonPackages = python.pythonPackages;
  };
}

