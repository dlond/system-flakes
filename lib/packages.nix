# Single source of truth for all packages across system and dev shells
# System uses defaults, dev-shells can override versions
{pkgs, ...}: {
  system = {
    # General utilities (modules install their own packages)
    utils = with pkgs; [
      bash
      curl
      fswatch
      gnused
      home-manager
      htop
      imagemagick
      jq
      mosh
      nmap
      tree-sitter
      unzip
      wget
      yq-go
      zip
    ];

    fonts = with pkgs; [
      nerd-fonts.jetbrains-mono
    ];

    security = with pkgs; [
      age
      gnupg
      sops
    ];

    apps = with pkgs; [
      brave
      claude-code
      discord-ptb
      obsidian
      raycast
    ];

    # Minimal dev tools for hacking
    development = {
      cpp = with pkgs; [
        cmake
        ninja
        # conan
        pkg-config
      ];

      python = with pkgs; [
        python314
        uv
      ];

      ocaml = with pkgs; [
        opam
      ];

      rust = with pkgs; [
        rustc
        cargo
        rustfmt
        clippy
      ];

      misc = with pkgs; [
        apple-sdk_26
        glow
        lua5_1
        luarocks
      ];

      # Neovim LSP/formatters for non-project languages
      # (Project-specific tools come from templates: uv for Python, opam for OCaml, etc.)
      neovim = with pkgs; [
        # LSP servers for scripting/config languages
        lua-language-server
        bash-language-server
        nixd
        yaml-language-server
        taplo # TOML
        vscode-langservers-extracted # JSON, HTML, CSS
        markdown-oxide
        sqls
        rust-analyzer

        # Formatters (language-agnostic or scripting)
        stylua # Lua
        alejandra # Nix
        shfmt # Bash/shell
        nodePackages.prettier # JSON, YAML, Markdown
        cmake-format # CMake (for C++ templates)

        # Linters
        statix # Nix
        shellcheck # Bash

        # Build tools needed by plugins
        gnumake # For telescope-fzf-native
      ];
    };

    homebrew = {
      taps = [];
      brews = [
        "asciinema"
        "mas"
        {
          name = "ollama";
          start_service = true;
          restart_service = true;
        }
        {
          name = "tor";
          start_service = true;
          restart_service = "changed";
        }
      ];
      casks = [
        "1password"
        "1password-cli"
        "anythingllm"
        "balenaetcher"
        "claude"
        "ghostty"
        "mullvad-vpn"
        "steam"
        "tor-browser"
        "transmission"
        "vlc"
        "whatsapp"
      ];
    };
  };
  # # Additional language servers for neovim
  # lsp = {
  #   scripting = with pkgs; [
  #     lua-language-server
  #     bash-language-server
  #     nixd
  #     yaml-language-server
  #   ];
  #
  #   config = with pkgs; [
  #     taplo # TOML
  #     nodePackages.vscode-langservers-extracted
  #   ];
  #
  #   # All LSPs for system neovim
  #   all =
  #     cpp.lsp
  #     ++ python.lsp
  #     ++ latex.lsp
  #     ++ ocaml.lsp
  #     ++ lsp.scripting
  #     ++ lsp.config
  #     ++ lsp.docs;
  # };
  #
  # # All formatters for system neovim
  # formatters = {
  #   all =
  #     cpp.formatters
  #     ++ python.formatters
  #     ++ latex.formatters
  #     ++ ocaml.formatters
  #     ++ (with pkgs; [
  #       stylua # Lua
  #       alejandra # Nix
  #       shfmt # Shell
  #       nodePackages.prettier # JS/TS/JSON/Markdown/HTML/CSS
  #       sqlfluff
  #     ]);
  # };
  #
  # # Debuggers for system neovim
  # debuggers = {
  #   all =
  #     [
  #       llvmPkg.lldb # C/C++ (includes lldb-dap)
  #       # debugpy is now included in pythonWithEssentials
  #     ]
  #     ++ lib.optionals pkgs.stdenv.isLinux (with pkgs; [
  #       gdb # GNU debugger
  #       valgrind # Memory checker
  #       delve # Go debugger
  #     ]);
  # };
  #
  # # System CLI tools (replaces lib/shared.nix)
  # system = {
  #   # Core system tools used by all environments
  #   cli =
  #     core.essential
  #     ++ core.search
  #     ++ core.utils
  #
  #       # Project tools (vanilla configs, available for quick prototyping)
  #       conan
  #       cmake
  #       cmake-format
  #       cmake-language-server
  #       ninja
  #       ccache
  #       bear # For compile_commands.json generation
  #       gtest # Google Test framework
  #       pkg-config
  #       llvmPkg.lldb # LLDB debugger with lldb-dap for DAP support
  #
  #       # Security
  #     ])
  # };
  #
  # # Complete package set for system neovim
  # neovim = {
  #   packages =
  #     core.essential
  #     ++ core.search
  #     ++ core.utils
  #     ++ lsp.all
  #     ++ formatters.all
  #     ++ [
  #       pythonWithEssentials # Python with debugging/Jupyter packages
  #       pkgs.uv # Python package manager
  #       pkgs.basedpyright # Python LSP
  #       pkgs.ruff # Python linter/formatter
  #       pkgs.imagemagick # For Jupyter/Molten visualization
  #       pkgs.poppler-utils # For Jupyter/Molten PDF support
  #       pkgs.nodejs # Node.js runtime for copilot.lua
  #     ];
  #
  #   pythonPackages = python.pythonPackages;
  # };
}
