{
  description = "OCaml development environment with Core libraries";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    system-flakes = {
      url = "github:dlond/system-flakes";
      # For local development: url = "path:/Users/dlond/dev/projects/system-flakes";
    };
  };

  outputs = { self, nixpkgs, flake-utils, system-flakes, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        # Import packages from system-flakes
        packages = import "${system-flakes}/lib/packages.nix" {
          inherit pkgs;
        };

        ocamlPackages = pkgs.ocaml-ng.ocamlPackages_5_2;
        
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            # OCaml compiler and tools
            ocamlPackages.ocaml
            ocamlPackages.dune_3
            ocamlPackages.ocaml-lsp
            ocamlPackages.ocamlformat
            ocamlPackages.utop
            ocamlPackages.odoc
            pkgs.opam

            # Core OCaml libraries (keeping for now as requested)
            ocamlPackages.core
            ocamlPackages.core_unix
            ocamlPackages.async
            ocamlPackages.ppx_jane

            # Testing and benchmarking
            ocamlPackages.alcotest
            ocamlPackages.qcheck
            ocamlPackages.benchmark
            ocamlPackages.core_bench

            # Data structures and algorithms
            ocamlPackages.containers
            ocamlPackages.iter

            # Math and statistics
            ocamlPackages.owl-base
          ] ++ packages.core.essential
            ++ packages.core.search
            ++ packages.core.utils;

          shellHook = ''
            echo "🐫 OCaml Development Environment"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "OCaml version: $(ocaml --version | head -n 1)"
            echo "Dune version: $(dune --version)"
            echo ""
            echo "Quick start:"
            echo "  • utop              - Interactive OCaml REPL"
            echo "  • dune init project - Create new project"
            echo "  • dune build        - Build project"
            echo "  • dune test         - Run tests"
            echo "  • dune exec         - Execute main program"
            echo ""
            echo "Libraries included:"
            echo "  • Core, Async, PPX extensions"
            echo "  • Testing: Alcotest, QCheck, Benchmark"
            echo "  • Data structures: Containers, Iter"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            
            # Set up OPAM environment if needed
            if [ ! -d "$HOME/.opam" ]; then
              echo "Initializing OPAM..."
              opam init --disable-sandboxing -n
            fi
            
            # Create project structure if starting fresh
            if [ ! -f "dune-project" ]; then
              echo ""
              echo "💡 No dune-project found. Create a new project with:"
              echo "   dune init project my_project"
            fi
          '';
          
          OCAMLPATH = "${ocamlPackages.core}/lib/ocaml/${ocamlPackages.ocaml.version}/site-lib";
        };
      });
}