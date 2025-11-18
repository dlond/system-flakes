# Python Project

A modern Python development environment using Nix for tooling and uv for package management.

## Philosophy

This template follows a clean separation of concerns:

- **Nix**: Provides Python interpreter and uv package manager
- **uv**: Manages all project dependencies AND development tools (basedpyright, ruff, debugpy)
- **pyproject.toml**: Declares dependencies and project metadata

This is similar to how you'd use Nix for C++/OCaml tools while using `conan`/`opam` for packages.

## Getting Started

```bash
# 1. Enter the directory (direnv loads Nix environment automatically)
cd your-project

# 2. Install dependencies including dev tools
uv sync --all-extras

# 3. Run your code
python -m myproject
# Or with an argument:
python -m myproject Alice

# 4. Run the tests
pytest

# 5. Run tests with coverage
pytest --cov
```

## Project Structure

```
.
├── src/
│   └── myproject/
│       ├── __init__.py
│       ├── __main__.py   # CLI entry point
│       └── core.py       # Core library functions
├── tests/
│   ├── __init__.py
│   └── test_core.py
├── pyproject.toml
├── flake.nix
└── .envrc
```

## How It Works

1. **Nix flake** provides Python 3.14 and uv package manager
2. **shellHook** automatically:
   - Initializes git repository if needed
   - Creates `.venv/` directory for virtual environment
   - Suggests running `uv sync --all-extras` to install dependencies
3. **.envrc** (direnv) automatically:
   - Loads the Nix environment
   - Activates the `.venv` when it exists
   - Sets `ENV_ICON="🐍"` for your shell prompt
4. **uv** installs all dependencies (including LSP tools) into `.venv/`
5. **Neovim** uses basedpyright/ruff from `.venv/` for IDE features

When you leave the directory, direnv automatically deactivates the venv!

## Starter Code

The template includes a simple CLI application to get you started:

**Library** (`core.py`):
- `greet(name)` - Returns a greeting string
- `add_numbers(a, b)` - Adds two numbers
- `Calculator` - A simple calculator class with method chaining

**CLI** (`__main__.py`):
- Simple command-line tool that greets a name
- Run with: `python -m myproject Alice`

**Tests** (`test_core.py`):
- pytest tests for all core functions
- Run with: `pytest`

You can modify or replace this starter code with your own implementation!

## Development

```bash
# Run tests
pytest

# Run tests with coverage
pytest --cov

# Format code
ruff format src tests

# Lint code
ruff check src tests

# Type check
basedpyright
```

## Adding Dependencies

```bash
# Add a runtime dependency
uv add numpy

# Add a dev dependency
uv add --dev ipython
```