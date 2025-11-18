{
  description = "OCaml development environment from dlond/system-flakes#ocaml";

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

      config = {
        name = "OCaml Development";

        withTest = true;
      };

      packages = with pkgs; [
        dune_3
        ocaml
        opam # Package manager - handles all project packages and dev tools
      ];
    in {
      devShells.default = pkgs.mkShell {
        name = config.name;
        nativeBuildInputs = packages;
        ENV_ICON = "❄️";

        shellHook = ''
          if [ ! -d ".git" ]; then
            git init
          fi

          echo "🐫 OCaml Development Environment"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "OCaml version: $(ocaml -vnum)"
          echo "Dune version: $(dune --version)"
          echo "Opam version: $(opam --version)"
          echo ""

          # Create local switch (without dependencies - fast!)
          if [ ! -d "_opam" ]; then
            echo "Creating local switch for OCaml $(ocaml -vnum)..."
            opam switch create . $(ocaml -vnum)
            echo ""

            # Generate .opam file from dune-project (doesn't need dependencies)
            eval $(opam env)
            dune build myproject.opam
            echo ""

            echo "Install dependencies:"
            echo "  • opam install . --deps-only                              (minimal - exe only)"
            echo "  • opam install . --deps-only --with-test                  (+ testing)"
            echo "  • opam install . --deps-only --with-dev-setup --with-test (+ LSP/tools)"
            echo ""
            echo "Then build with:"
            echo "  • dune build @install  (builds lib + exe, skips tests)"
            echo "  • dune build           (builds everything including tests)"
            echo ""
          fi

          echo "Development workflow:"
          echo "  • dune build         - Build project"
          echo "  • dune test          - Run tests"
          echo "  • utop               - Interactive REPL"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        '';
      };
    });
}
