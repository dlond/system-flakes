# OCaml Project Template

A modern OCaml development environment using Nix for tooling and Opam for package management.

## Philosophy

This template follows a clean separation of concerns:

- **Nix**: Provides base development tools (OCaml compiler, Dune, Opam)
- **Opam**: Manages all project dependencies AND development tools (LSP, formatter, etc.)
- **Dune**: Builds your project and generates editor integration configs

This is similar to how you'd use Nix for Python/C++ tools while using `uv`/`conan` for packages.

## Getting Started

```bash
# 1. Enter the directory (direnv loads Nix environment automatically)
cd your-project

# 2. Create local opam switch
opam switch create . $(ocaml -vnum)

# 3. Generate .opam file
dune build myproject.opam

# 4. Install dependencies (choose one):
opam install . --deps-only                              # Minimal - exe only
opam install . --deps-only --with-test                  # + testing
opam install . --deps-only --with-dev-setup --with-test # + LSP/tools

# 5. Build the project
dune build @install  # Builds lib + exe (skips tests - use with --deps-only)
dune build           # Builds everything (requires --with-test)

# 6. Run the application
dune exec bin/main.exe
# Or with an argument:
dune exec bin/main.exe -- Alice

# 7. Run the tests (requires --with-test)
dune test

# 8. Try the REPL with your library loaded
utop -require mylib
```

### Customizing the Template

Before starting development, you can rename the project by updating:
- `dune-project`: Change `(name myproject)` and package name
- `lib/dune`, `bin/dune`, `test/dune`: Update `myproject.lib` references
- `dune-project`: Update source field `username/myproject`
- Update author and maintainer information
- Add any additional dependencies you need

## Project Structure

```
.
├── flake.nix          # Nix development environment (tools only)
├── .envrc             # Direnv integration
├── dune-project       # Project metadata and dependencies
├── .ocamlformat       # Formatter configuration
├── .gitignore         # Git ignore rules
├── bin/               # Executable sources
│   ├── dune          # Build config for executable
│   └── main.ml       # CLI application using cmdliner
├── lib/               # Library sources
│   ├── dune          # Build config for library
│   └── greet.ml      # Example library module
└── test/              # Tests
    ├── dune          # Build config for tests
    └── test_greet.ml # Alcotest tests for greet module
```

## Adding Dependencies

Edit `dune-project` and add your dependencies:

```ocaml
(package
 (name my-project)
 (depends
   ocaml
   dune
   ;; Project dependencies (always installed with --deps-only)
   yojson
   cmdliner
   lwt

   ;; Testing dependencies (installed with --with-test)
   (alcotest :with-test)

   ;; Development tools (installed with --with-dev-setup)
   (ocaml-lsp-server :with-dev-setup)
   (merlin :with-dev-setup)
   (ocamlformat :with-dev-setup)
   (utop :with-dev-setup)))
```

Then regenerate the .opam file and install:

```bash
dune build myproject.opam
opam install . --deps-only                              # Just project deps
opam install . --deps-only --with-test                  # + testing
opam install . --deps-only --with-dev-setup --with-test # + LSP/tools
```

Dune will auto-generate the `.opam` file from this.

## Common Commands

```bash
# Build
dune build @install  # Builds lib + exe only (skips tests)
dune build           # Builds everything including tests

# Run executable
dune exec bin/main.exe

# Run tests (requires --with-test)
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

## Starter Code

The template includes a simple CLI application to get you started:

**Library** (`lib/greet.ml`):
- `hello` - Returns a greeting string
- `goodbye` - Returns a farewell string
- `greet_many` - Greets multiple names

**Executable** (`bin/main.ml`):
- CLI tool using cmdliner that greets a name
- Run with: `dune exec bin/main.exe -- Alice`

**Tests** (`test/test_greet.ml`):
- Alcotest tests for all greet functions
- Run with: `dune test`

You can modify or replace this starter code with your own implementation!

## Resources

- [Real World OCaml](https://dev.realworldocaml.org/)
- [OCaml.org Documentation](https://ocaml.org/docs)
- [Dune Documentation](https://dune.readthedocs.io/)
- [Opam Documentation](https://opam.ocaml.org/doc/)
