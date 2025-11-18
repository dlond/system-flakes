# OCaml Project Template

A modern OCaml development environment using Nix for tooling and Opam for package management.

## Philosophy

This template follows a clean separation of concerns:

- **Nix**: Provides base development tools (OCaml compiler, Dune, Opam)
- **Opam**: Manages all project dependencies AND development tools (LSP, formatter, etc.)
- **Dune**: Builds your project and generates editor integration configs

This is similar to how you'd use Nix for Python/C++ tools while using `uv`/`conan` for packages.

## Quick Start

1. **Initialize the project** from this template:
   ```bash
   nix flake init -t github:dlond/system-flakes#ocaml
   ```

2. **Enter the development environment**:
   ```bash
   # Direnv will automatically load the nix shell
   cd your-project
   ```

3. **Update dune-project** with your project details:
   - Replace `PROJECT_NAME` with your project name
   - Update author, maintainers, source
   - Add your dependencies

4. **Create a local opam switch** (first time only):
   ```bash
   opam switch create . 5.3.0 --deps-only --with-dev-setup
   ```

   This installs:
   - All dependencies from `dune-project`
   - Development tools (LSP, merlin, formatter, utop)

5. **Build your project**:
   ```bash
   dune build
   ```

6. **Open in your editor** - LSP should work immediately!

## Project Structure

```
.
├── flake.nix          # Nix development environment (tools only)
├── .envrc             # Direnv integration
├── dune-project       # Project metadata and dependencies
├── .ocamlformat       # Formatter configuration
├── .gitignore         # Git ignore rules
├── bin/               # Executable sources (create with `dune init exe`)
├── lib/               # Library sources (create with `dune init lib`)
└── test/              # Tests (create with `dune init test`)
```

## Adding Dependencies

Edit `dune-project` and add your dependencies:

```ocaml
(package
 (name my-project)
 (depends
   ocaml
   dune
   ;; Add project dependencies here
   yojson
   cmdliner
   lwt

   ;; Dev tools (installed with --with-dev-setup)
   (ocaml-lsp-server :with-dev-setup)
   (merlin :with-dev-setup)
   (ocamlformat :with-dev-setup)
   (utop :with-dev-setup)

   ;; Testing (installed with --with-test)
   (alcotest :with-test)))
```

Then install them:

```bash
opam install . --deps-only --with-dev-setup
```

Dune will auto-generate the `.opam` file from this.

## Common Commands

```bash
# Build
dune build

# Run executable
dune exec bin/main.exe

# Run tests
dune test

# Clean build artifacts
dune clean

# Interactive REPL
utop

# Format code
dune build @fmt --auto-promote

# Watch mode (rebuild on file changes)
dune build --watch
```

## Creating Project Structure

```bash
# Create an executable
dune init exe my_app bin

# Create a library
dune init lib my_lib lib

# Create tests
dune init test my_tests test
```

## Multiple Executables

If you have multiple executables in `bin/`, ensure they all share the same dependencies in `bin/dune`:

```ocaml
(executable
 (name tool1)
 (libraries common_deps lib1 lib2))  ;; Same libraries

(executable
 (name tool2)
 (libraries common_deps lib1 lib2))  ;; Keep consistent
```

This ensures the LSP can properly resolve all modules.

## Troubleshooting

### LSP shows "Unbound module" errors

1. Make sure you've created the local opam switch:
   ```bash
   opam switch create . 5.3.0 --deps-only --with-dev-setup
   ```

2. Rebuild to regenerate merlin configs:
   ```bash
   dune clean && dune build
   ```

3. Restart the LSP:
   ```vim
   :LspRestart
   ```

### "Corrupted compiled interface" errors

This happens when LSP tools and project dependencies use different OCaml versions.

**Solution**: Make sure dev tools are installed via opam (with `:with-dev-setup` in `dune-project`), not nix.

### Check active opam switch

```bash
opam switch show
```

Should show the local project path like `/path/to/your-project`, not "default".

## How It Works

1. **Nix flake** provides OCaml 5.3.0, Dune, and Opam
2. **shellHook** automatically:
   - Clears `OCAMLPATH` so opam controls packages
   - Runs `eval $(opam env)` if `_opam/` exists
3. **opam** installs packages into local `_opam/` directory
4. **dune** builds and generates `.merlin-conf/` files
5. **ocaml-lsp-server** (from opam) uses merlin configs for IDE features

All tools use the same OCaml compiler = no version conflicts!

## Example: Simple CLI Tool

```ocaml
(* bin/main.ml *)
open Cmdliner

let greet name =
  Printf.printf "Hello, %s!\n" name

let name =
  let doc = "Name to greet" in
  Arg.(value & pos 0 string "World" & info [] ~docv:"NAME" ~doc)

let greet_cmd =
  let doc = "Greet someone" in
  let info = Cmd.info "greet" ~doc in
  Cmd.v info Term.(const greet $ name)

let () = exit (Cmd.eval greet_cmd)
```

```ocaml
(* bin/dune *)
(executable
 (name main)
 (libraries cmdliner))
```

Build and run:
```bash
dune build
dune exec bin/main.exe Alice
# Output: Hello, Alice!
```

## Resources

- [Real World OCaml](https://dev.realworldocaml.org/)
- [OCaml.org Documentation](https://ocaml.org/docs)
- [Dune Documentation](https://dune.readthedocs.io/)
- [Opam Documentation](https://opam.ocaml.org/doc/)
