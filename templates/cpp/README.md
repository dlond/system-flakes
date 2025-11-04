# C++ Development

Modern C++ development environment with Conan package management and CMake build system.

## Features

- 🚀 **C++23** - Modern C++ standard
- 📦 **Conan 2** - Package management
- 🔧 **CMake Presets** - Consistent build configuration
- 🛠️ **LLVM Toolchain** - Latest compiler
- 🔍 **clang-tidy** - Static analysis
- ⚡ **ccache** - Build acceleration
- 🧪 **Testing** - gtest framework


## Configuration

### Configuration Options

All available configuration options with defaults and explanations:

| Option | Default | Description | Current |
|--------|---------|-------------|---------|
| **cpp.essential** | | *Core compilation settings* | |
| \`cppStandard\` | \`20\` | C++ standard version (17, 20, 23) | **23** |
| \`defaultProfile\` | \`"release"\` | Default Conan profile | release |
| \`enableLTO\` | \`false\` | Link-time optimization | false |
| \`useThinLTO\` | \`false\` | Use ThinLTO (faster than full LTO) | false |
| \`enableExceptions\` | \`true\` | C++ exception handling | true |
| \`enableRTTI\` | \`true\` | Runtime type information | true |
| \`optimizationLevel\` | \`2\` | Optimization (-O0 to -O3, s, z) | 2 |
| \`marchNative\` | \`false\` | CPU-specific optimizations | false |
| \`alignForCache\` | \`false\` | Cache-line alignment (64 bytes) | false |
| \`warningLevel\` | \`"all"\` | Compiler warnings (none/default/all/extra) | all |
| **cpp.devTools** | | *Development productivity tools* | |
| \`enable\` | \`true\` | Include dev tools | true |
| \`enableClangTidy\` | \`false\` | Static analysis linting | **true** |
| \`enableCppCheck\` | \`false\` | Additional static analysis | false |
| \`enableCcache\` | \`true\` | Build caching | true |
| \`ccacheMaxSize\` | \`"5G"\` | Cache size limit | 5G |
| \`enablePreCommitHooks\` | \`false\` | Git pre-commit hooks | false |
| **cpp.testing** | | *Testing framework configuration* | |
| \`enable\` | \`true\` | Include test framework | true |
| \`testFramework\` | \`"gtest"\` | Framework (gtest/catch2/doctest) | gtest |
| \`enableCoverage\` | \`false\` | Code coverage reporting | false |
| \`enableSanitizers\` | \`false\` | Memory/UB sanitizers (debug) | false |
| **cpp.performance** | | *Performance optimization tools* | |
| \`enable\` | \`false\` | Include performance libraries | false |
| \`enableBenchmarks\` | \`false\` | Google Benchmark library | false |
| **cpp.linuxPerf** | | *Linux-specific performance tools* | |
| \`enable\` | \`false\` | DPDK, perf-tools, io_uring | false |
| **cpp.docs** | | *Documentation generation* | |
| \`enable\` | \`false\` | Include doc tools | false |
| \`enableDocs\` | \`false\` | Doxygen + Sphinx | false |

**Bold** values indicate overrides from defaults.

### Current Configuration

Settings from \`flake.nix\`:

\`\`\`nix
config = {
  cpp.essential = {
    cppStandard = 23;
  };cpp.devTools = {
  enableClangTidy = true;
};
};
\`\`\`

## Compiler Flags

**Release Build:**
- \`-O2\` - Optimization level


**Debug Build:**
- \`-O0 -g3\` - No optimization, full debug info


## Quick Start

\`\`\`bash
# Enter the development environment
nix develop

# Debug build
conan install . --profile=debug --build=missing
cmake --preset=conan-debug
cmake --build --preset=conan-debug
./build/Debug/app

# Release build
conan install . --profile=release --build=missing
cmake --preset=conan-release
cmake --build --preset=conan-release
./build/Release/app
\`\`\`

## Project Structure

\`\`\`
.
├── flake.nix              # Nix environment configuration
├── CMakeLists.txt         # CMake build configuration
├── conanfile.txt          # Conan dependencies
├── .conan2/               # Local Conan profiles
├── include/               # Header files
├── src/                   # Source files
│   └── main.cpp
├── tests/                 # Unit tests
└── build/                 # Build output (git-ignored)
    ├── Debug/
    └── Release/
\`\`\`

## Adding Dependencies

Add to \`conanfile.txt\`:

\`\`\`ini
[requires]
fmt/10.1.1
spdlog/1.12.0

[generators]
CMakeDeps
CMakeToolchain

[layout]
cmake_layout
\`\`\`

Then reinstall:
\`\`\`bash
conan install . --profile=release --build=missing
cmake --preset=conan-release
\`\`\`

## Tools Included

- **Compiler**: Clang with libc++
- **Build**: CMake, Ninja
- **Package Manager**: Conan 2.x
- **Language Server**: clangd
- **Formatter**: clang-format
- **Static Analysis**: clang-tidy
- **Cache**: ccache
- **Testing**: gtest


## Development Tips

1. **IDE Integration**: The environment generates \`compile_commands.json\` for clangd support
2. **Clean Build**: \`rm -rf build/ && conan install . --profile=release --build=missing\`
3. **Switch Profiles**: Use \`--preset=conan-debug\` or \`--preset=conan-release\`
4. **Faster Builds**: ccache enabled - subsequent builds will be faster


## Troubleshooting

**Conan packages not found:**
\`\`\`bash
conan remove "*" -c
conan install . --profile=release --build=missing
\`\`\`

**CMake preset not found:**
\`\`\`bash
ls CMakePresets.json  # Should exist after conan install
\`\`\`

**Build errors:**
\`\`\`bash
# Force rebuild dependencies
conan install . --profile=release --build=missing --build=<package>
\`\`\`

---
*Generated by nix develop based on flake.nix configuration*

