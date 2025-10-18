# Development Templates

These templates provide isolated development environments with specific tool versions, separate from the system defaults.

## Available Templates

### Python (`python`)
Python development environment with uv for dependency management.

**Features:**
- Configurable Python version (3.10, 3.11, 3.12, 3.13, 3.14)
- uv for fast package management in virtual environments
- Neovim integration (debugpy, pynvim, jupyter-client)
- LSP: basedpyright, ruff
- Project dependencies isolated in `.venv`

**Usage:**
```bash
nix flake init -t github:dlond/system-flakes#python
direnv allow
uv venv
source .venv/bin/activate
uv pip install -r requirements.txt  # or uv add <package>
```

### C++ (`cpp`)
C++ development with Conan package manager and CMake presets.

**Features:**
- Configurable LLVM version for tools
- Conan manages compiler toolchain via profiles
- CMake presets for build configuration
- Neovim tools: clangd, clang-format, lldb-dap
- Compiler toolchain defined in Conan profiles, not Nix

**Usage:**
```bash
nix flake init -t github:dlond/system-flakes#cpp
direnv allow
conan profile detect --force  # Create/update Conan profile
conan install . --build=missing
cmake --preset conan-default
cmake --build --preset conan-release
```

### Python + C++ (`python-cpp`)
Combined environment for Python bindings and mixed projects.

**Features:**
- Both Python and C++ tools
- pybind11 included for bindings
- uv for Python packages, Conan for C++ dependencies
- Suitable for projects with Python extensions in C++

**Usage:**
```bash
nix flake init -t github:dlond/system-flakes#python-cpp
direnv allow
# Python setup
uv venv && source .venv/bin/activate
# C++ setup  
conan install . --build=missing
cmake --preset conan-default -DPYTHON_EXECUTABLE=$(which python)
cmake --build --preset conan-release
```

## Key Concepts

### Version Independence
- Templates can use different versions than system defaults
- Python version configurable in flake.nix
- LLVM version configurable (for tools only)
- Actual C++ compiler managed by Conan profiles

### Dependency Management
- **Python**: All project dependencies via uv in `.venv`
- **C++**: All dependencies via Conan
- **Nix**: Only provides minimal tools for Neovim integration

### Neovim Integration
Each template provides:
- Language servers (LSPs)
- Formatters
- Debuggers (DAP)
- Essential packages for Neovim Python host

### Isolation
- Project dependencies never pollute system
- Virtual environments for Python
- Conan manages C++ build environments
- Templates are self-contained

## Customization

Edit the template's `flake.nix` to:
- Change Python version: `pythonVersion = "3.11"`
- Change LLVM tools version: `llvmVersion = "18"`
- Add/remove tools as needed

## Testing

To test a template:
```bash
cd /tmp
mkdir test-python && cd test-python
nix flake init -t path:/Users/dlond/dev/projects/system-flakes#python
nix develop
```