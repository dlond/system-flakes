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

      # More useful stuff here I guess
      config = {
        name = "${baseNameOf ./.}";
        withTest = true;
      };

      packages = with pkgs; [
        opam

        gnumake
        pkg-config
        git
      ];
    in {
      devShells.default = pkgs.mkShell {
        name = config.name;
        nativeBuildInputs = packages;
        ENV_ICON = "❄️";

        shellHook = ''
          # project switch init
          if [ ! -d "./_opam" ]; then
            echo "🐪 No project opam switches found. Creating ..."

            # worktrees just link switches
            if [ -f ".git" ]; then
              MAIN_WT=$(git worktree list | awk 'NR == 1 { print $1; exit }')
              echo "   Linking project opam switch at $MAIN_WT ..."
              opam switch link $MAIN_WT

              echo "✅ Project switch linked."
            else
              echo "  Creating project opam switch $PWD ..."
              opam switch create "$PWD" \
                ocaml \
                dune \
                ocaml-lsp-server \
                ocamlformat \
                merlin \
                utop

              echo "✅ Project switch created."
            fi
          fi

          # project init
          if [ ! -f "dune-project" ]; then
            echo "  Initializing dune project ..."
            dune init project ${config.name} "$PWD"

            # update "${config.name}.opam"
            # dune build >/dev/null 2>&1

            echo "✅ dune project initiated."
          fi

          echo "🐫 OCaml Development Environment"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "OCaml version: $(ocaml -vnum)"
          echo "Dune version: $(dune --version)"
          echo "Opam version: $(opam --version)"
          echo ""
        '';
      };
    });
}
