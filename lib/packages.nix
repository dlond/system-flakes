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
