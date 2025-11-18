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
          echo "🐫 OCaml Development Environment"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "OCaml version: $(ocaml -vnum)"
          echo "Dune version: $(dune --version)"
          echo "Opam version: $(opam --version)"
          echo ""

          # Create local switch
          if [ ! -d "_opam" ]; then
            echo "Creating local switch for OCaml $(ocaml -vnum)..."
            echo "> opam switch create . $(ocaml -vnum) --deps-only --with-dev-setup --with-test"
            opam switch create . $(ocaml -vnum) --deps-only --with-dev-setup --with-test
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
