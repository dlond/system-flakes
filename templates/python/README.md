# Python Project

A Python project template with uv package management and nix development environment.

## Setup

```bash
# Allow direnv to load the environment
direnv allow

# Create virtual environment
uv venv

# Install dependencies including dev tools
uv pip install -e ".[dev]"
```

## Project Structure

```
.
├── src/
│   └── myproject/
│       ├── __init__.py
│       └── core.py
├── tests/
│   ├── __init__.py
│   └── test_core.py
├── pyproject.toml
├── flake.nix
└── .envrc
```

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