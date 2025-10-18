# Python + C++ Project

A project template combining Python and C++ with pybind11 bindings.

## Setup

```bash
# Allow direnv to load the environment
direnv allow

# Configure Conan profile
conan profile detect --force

# Install C++ dependencies
conan install . --build=missing

# Create Python virtual environment
uv venv
source .venv/bin/activate

# Build C++ extension
cmake --preset conan-default
cmake --build --preset conan-release

# Install Python package in editable mode
uv pip install -e ".[dev]"
```

## Project Structure

```
.
├── include/           # C++ headers
│   └── myproject/
│       ├── core.h
│       └── math_ops.h
├── src/              # C++ sources
│   ├── main.cpp      # C++ CLI example
│   ├── core.cpp
│   ├── math_ops.cpp
│   └── bindings.cpp  # Pybind11 bindings
├── python/           # Python package
│   └── myproject/
│       ├── __init__.py
│       └── high_level.py
├── tests/            # Tests
│   ├── CMakeLists.txt
│   ├── test_cpp_core.cpp    # C++ tests
│   └── test_python.py        # Python tests
├── CMakeLists.txt
├── conanfile.txt
├── pyproject.toml
├── flake.nix
└── .envrc
```

## Development

### Python Development
```bash
# Run Python tests
pytest

# Use the module
python -c "from myproject import add_arrays; print(add_arrays([1,2,3], [4,5,6]))"

# Format/lint Python
ruff format python tests
ruff check python tests
```

### C++ Development
```bash
# Build C++ only
cmake --build --preset conan-release

# Run C++ tests
ctest --preset conan-release

# Run C++ CLI
./build/Release/myproject_cli
```

### Rebuilding Extension
After C++ changes:
```bash
cmake --build --preset conan-release
```

The Python module will be automatically updated in `python/myproject/_myproject_ext.so`

## Adding Dependencies

### C++ Dependencies
Edit `conanfile.txt`:
```ini
[requires]
pybind11/2.11.1
eigen/3.4.0  # Example
```

### Python Dependencies
```bash
uv add scipy
uv add --dev ipython
```