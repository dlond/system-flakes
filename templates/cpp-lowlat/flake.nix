{
  description = "C++ low-latency development environment for high-performance systems";

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

        # Import packages from system-flakes with LLVM 18 for performance
        packages = import "${system-flakes}/lib/packages.nix" {
          inherit pkgs;
          llvmVersion = "18";  # Latest LLVM for performance optimizations
        };
      in {
        devShells.default = pkgs.mkShell {
          buildInputs =
            # C++ packages with analysis tools enabled
            packages.cpp.packages {
              llvmVersion = "18";
              packageManager = "conan";
              testFramework = "gtest";
              withAnalysis = true;
              withDocs = false;
              withBazel = false;
            }
            # Additional performance libraries
            ++ (with pkgs; [
              google-benchmark
              boost
              jemalloc
              mimalloc
              tbb
              catch2_3  # Additional testing framework
            ])
            # Linux-specific performance tools
            ++ pkgs.lib.optionals pkgs.stdenv.isLinux (with pkgs; [
              perf-tools
              valgrind
              liburing
              dpdk
            ])
            # Core development tools from system-flakes
            ++ packages.core.search
            ++ packages.core.utils;

          shellHook = ''
            echo "⚡ C++ Low-Latency Development Environment"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "Clang: $(clang --version | head -n 1)"
            echo "CMake: $(cmake --version | head -n 1)"
            echo "Conan: $(conan --version)"
            echo ""
            echo "Quick start:"
            echo "  • conan profile detect --force  - Setup Conan profile"
            echo "  • conan install . --build=missing"
            echo "  • cmake --preset conan-release"
            echo "  • cmake --build --preset conan-release"
            echo ""
            echo "Available presets:"
            echo "  • conan-debug     - Debug symbols, sanitizers"
            echo "  • conan-release   - Optimized, LTO enabled"
            echo "  • conan-relwithdebinfo - Optimized with debug info"
            echo ""
            echo "Performance tools:"
            ${pkgs.lib.optionalString pkgs.stdenv.isLinux ''
            echo "  • perf record ./app    - CPU profiling (Linux)"
            echo "  • valgrind --tool=cachegrind ./app (Linux)"
            ''}
            echo "  • lldb ./app          - LLVM debugger"
            echo "  • google-benchmark    - Microbenchmarking"
            echo ""
            echo "Key optimization techniques:"
            echo "  • Lock-free data structures"
            echo "  • Cache-line optimization"
            echo "  • Memory pool allocators"
            echo "  • SIMD instructions"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            
            # Check for Conan profiles
            if [ ! -d ~/.conan2/profiles ]; then
              echo ""
              echo "No Conan profiles found. Run 'conan profile detect --force' to create default profile."
            fi

            # Check for project files
            if [ ! -f "CMakeLists.txt" ]; then
              echo ""
              echo "💡 No CMake project found. Create one with:"
              echo "   Use the template CMakeLists.txt provided"
            fi

            if [ ! -f "conanfile.txt" ] && [ ! -f "conanfile.py" ]; then
              echo ""
              echo "💡 No conanfile found. Use the template conanfile.txt provided"
            fi
          '';

          # Don't set compiler flags here - let Conan profiles handle it
          # Conan will manage CC, CXX, CXXFLAGS, LDFLAGS through profiles
        };
      });
}