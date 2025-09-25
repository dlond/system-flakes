# Single source of truth for packages across system and dev shells
{pkgs}: let
  inherit (pkgs) lib;
in {
  python = rec {
    core = pythonPkg: with pkgs; [
      pythonPkg
      uv
      ruff
      basedpyright
      black  # formatter
      # Essential tools for neovim
      ripgrep
      fd
    ];

    # Backward compatibility - default to Python 3.11
    coreDefault = core pkgs.python311;

    molten = with pkgs; [
      imagemagick
      poppler_utils
      netpbm
      texlive.combined.scheme-basic
      quarto
    ];

    pythonPackages = ps: with ps; [
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

  cpp = rec {
    core = compilerPkg: with pkgs; [
      compilerPkg
      clang-tools  # for clangd, clang-format
      gnumake
      pkg-config
      # Essential tools for neovim
      ripgrep
      fd
      shfmt  # shell formatter for embedded scripts
    ];

    # Backward compatibility - default to Clang 19
    coreDefault = core pkgs.clang_19;

    cmakeTools = with pkgs; [
      cmake
      cmake-format
      cmake-language-server
      ninja
    ];

    bazelTools = with pkgs; [
      bazel
      buildtools
      buildifier
    ];

    conanTools = with pkgs; [
      conan
    ];

    debugger = with pkgs; [
      lldb
    ] ++ lib.optionals pkgs.stdenv.isLinux [
      gdb
      valgrind
    ];
  };

  rust = {
    core = with pkgs; [
      # Core tools (rust toolchain provided separately)
      cargo-watch
      cargo-edit
      cargo-outdated
      cargo-audit
      cargo-expand
      cargo-generate
      # rust-analyzer provided by rust-overlay

      # Build essentials
      pkg-config
      openssl

      # Essential tools for neovim
      ripgrep
      fd
      rustfmt
    ];

    wasm = with pkgs; [
      wasm-pack
      wasm-bindgen-cli
      trunk
      nodePackages.nodejs
    ];

    tauri = with pkgs; [
      cargo-tauri
      nodePackages.nodejs
      nodePackages.pnpm
      webkit2gtk
      libsoup
      openssl
    ];

    database = with pkgs; [
      sqlx-cli
      diesel-cli
      postgresql
      sqlite
    ];
  };

  latex = {
    core = with pkgs; [
      # Core LaTeX tools (texlive provided separately)
      texlab  # LSP
    ] ++ lib.optionals pkgs.stdenv.isLinux [
      zathura  # PDF viewer with synctex support (Linux only)
    ];

    pandoc = with pkgs; [
      pandoc
      librsvg  # for SVG support in pandoc
      python3Packages.pandocfilters
    ];

    graphics = with pkgs; [
      ghostscript
      imagemagick
      inkscape  # for SVG editing
      gnuplot
      graphviz
      poppler_utils  # for pdfcrop
    ];

    python = with pkgs; [
      (python3.withPackages (ps: with ps; [
        pygments  # for minted
        matplotlib  # for pythontex plots
      ]))
    ];
  };

  # Common tools needed across all dev environments
  common = {
    lsp = with pkgs; [
      nixd  # for flake.nix editing
      bash-language-server  # for shell scripts
    ];
  };

  neovim = {
    lsp = with pkgs; [
      clang-tools
      basedpyright
      ruff
      nixd
      texlab
      cmake-language-server
      bash-language-server
      lua-language-server
      rust-analyzer
    ];

    formatters = with pkgs; [
      stylua
      alejandra
      black
      shfmt
      cmake-format
      rustfmt
    ];

    tools = with pkgs; [
      ripgrep
      fd
      gnumake
      gcc
    ];
  };
}