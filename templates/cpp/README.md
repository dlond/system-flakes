# C++ Project

A C++ project template with Conan package management and CMake presets.

## Setup

```bash
# Allow direnv to load the environment
direnv allow

# Configure Conan profile (first time only)
conan profile detect --force

# Install dependencies
conan install . --build=missing

# Configure with CMake preset
cmake --preset conan-default

# Build
cmake --build --preset conan-release
```

## Project Structure

```
.
├── include/
│   └── myproject/
│       ├── core.h
│       └── calculator.h
├── src/
│   ├── main.cpp
│   ├── core.cpp
│   └── calculator.cpp
├── tests/
│   ├── CMakeLists.txt
│   ├── test_core.cpp
│   └── test_calculator.cpp
├── CMakeLists.txt
├── conanfile.txt
├── flake.nix
└── .envrc
```

## Development

```bash
# Build in debug mode
cmake --build --preset conan-debug

# Run tests
ctest --preset conan-release

# Or run tests directly
./build/Release/tests/test_myproject

# Generate compile_commands.json for clangd
cmake --preset conan-default

# Format code
clang-format -i src/*.cpp include/myproject/*.h tests/*.cpp
```

## Adding Dependencies

Edit `conanfile.txt` and add dependencies:
```ini
[requires]
gtest/1.14.0
fmt/10.2.1
boost/1.83.0  # Example
```

Then reinstall:
```bash
conan install . --build=missing
```