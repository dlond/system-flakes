# C++ Low-Latency Development

High-performance C++ development environment optimized for low-latency systems.

## Features

- ⚡ **Maximum Performance** - Aggressive optimizations enabled
- 🚀 **C++23** - Latest language features
- 🔥 **LTO** - Link-time optimization enabled (ThinLTO)
- 🎯 **CPU-Specific** - Native architecture targeting
- 📊 **Benchmarking** - Performance measurement tools
- 💾 **Cache Alignment** - Optimized for cache lines
- 🐧 **Linux Perf Tools** - Advanced profiling capabilities


## Configuration

### Configuration Options

All available configuration options with defaults and explanations:

| Option | Default | Description | Current |
|--------|---------|-------------|---------|
| **cpp.essential** | | *Core compilation settings* | |
| \`cppStandard\` | \`20\` | C++ standard version (17, 20, 23) | **23** |
| \`defaultProfile\` | \`"release"\` | Default Conan profile | release |
| \`enableLTO\` | \`false\` | Link-time optimization | **true** |
| \`useThinLTO\` | \`false\` | Use ThinLTO (faster than full LTO) | **true** |
| \`enableExceptions\` | \`true\` | C++ exception handling | **false** |
| \`enableRTTI\` | \`true\` | Runtime type information | **false** |
| \`optimizationLevel\` | \`2\` | Optimization (-O0 to -O3, s, z) | **3** |
| \`marchNative\` | \`false\` | CPU-specific optimizations | **true** |
| \`alignForCache\` | \`false\` | Cache-line alignment (64 bytes) | **true** |
| \`warningLevel\` | \`"all"\` | Compiler warnings (none/default/all/extra) | extra |
| **cpp.devTools** | | *Development productivity tools* | |
| \`enable\` | \`true\` | Include dev tools | true |
| \`enableClangTidy\` | \`false\` | Static analysis linting | false |
| \`enableCcache\` | \`true\` | Build caching | true |
| \`ccacheMaxSize\` | \`"5G"\` | Cache size limit | 5G |
| \`enablePreCommitHooks\` | \`false\` | Git pre-commit hooks | false |
| **cpp.analysis** | | *Static analysis tools* | |
| \`enable\` | \`false\` | Include analysis tools | false |
| \`enableCppCheck\` | \`false\` | CppCheck analysis | false |
| \`enableIncludeWhatYouUse\` | \`false\` | Include-what-you-use | false |
| **cpp.testing** | | *Testing framework configuration* | |
| \`enable\` | \`true\` | Include test framework | true |
| \`testFramework\` | \`"gtest"\` | Framework (gtest/catch2/doctest) | gtest |
| \`enableCoverage\` | \`false\` | Code coverage reporting | false |
| \`enableSanitizers\` | \`false\` | Memory/UB sanitizers (debug) | false |
| **cpp.performance** | | *Performance optimization tools* | |
| \`enable\` | \`false\` | Include performance libraries | **true** |
| \`enableBenchmarks\` | \`false\` | Google Benchmark library | **true** |
| **cpp.linuxPerf** | | *Linux-specific performance tools* | |
| \`enable\` | \`false\` | DPDK, perf-tools, io_uring | **true** |
| **cpp.docs** | | *Documentation generation* | |
| \`enable\` | \`false\` | Include doc tools | false |
| \`enableDocs\` | \`false\` | Doxygen + Sphinx | false |

**Bold** values indicate overrides from defaults.

### Current Configuration

Settings from \`flake.nix\`:

\`\`\`nix
config = {
  cpp.essential = {
    cppStandard = 23;enableLTO = true;useThinLTO = true;
enableExceptions = false;
enableRTTI = false;
optimizationLevel = 3;marchNative = true;alignForCache = true;
  };cpp.performance = {
  enable = true;
  enableBenchmarks = true;
};cpp.linuxPerf = {
  enable = true;
};
};
\`\`\`

## Compiler Flags

**Release Build:**
- \`-O3\` - Optimization level
- `-march=native -mtune=native` - CPU-specific instructions
- `-flto=thin` - Link-time optimization
- `-fno-exceptions` - No exception handling
- `-fno-rtti` - No RTTI overhead
- `-falign-functions=64` - Cache-line alignment


**Debug Build:**
- \`-O0 -g3\` - No optimization, full debug info
- `-fsanitize=address,undefined` - Memory and UB detection


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
├── bench/                 # Benchmarks
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
- **Cache**: ccache
- **Testing**: gtest
- **Benchmarking**: Google Benchmark


## Development Tips

1. **IDE Integration**: The environment generates \`compile_commands.json\` for clangd support
2. **Clean Build**: \`rm -rf build/ && conan install . --profile=release --build=missing\`
3. **Switch Profiles**: Use \`--preset=conan-debug\` or \`--preset=conan-release\`
4. **Faster Builds**: ccache enabled - subsequent builds will be faster
## Benchmarking

\`\`\`cpp
#include <benchmark/benchmark.h>

static void BM_Example(benchmark::State& state) {
    for (auto _ : state) {
        // Code to benchmark
    }
}
BENCHMARK(BM_Example);
\`\`\`

Run: \`./build/Release/bench_app\`


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

