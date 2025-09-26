{
  pkgs,
  projectName ? "cpp-python-project",
  pythonVersion ? "3.11",  # Same default as Python projects
  cppStandard ? "20",       # Same default as C++ projects
  llvmVersion ? "20",       # Same default as C++ projects
  extraPackages ? [],
  ...
}: let
  packages = import ../lib/packages.nix {
    inherit pkgs pythonVersion llvmVersion;
  };

  llvm = pkgs."llvmPackages_${llvmVersion}" or pkgs.llvmPackages;

  # Use custom stdenv with the selected LLVM to prevent toolchain pollution
  customStdenv = pkgs.overrideCC pkgs.stdenv llvm.clang;

  # Use the same Python selection logic from packages.nix
  pythonPkg =
    if pythonVersion == "3.10" then pkgs.python310
    else if pythonVersion == "3.11" then pkgs.python311
    else if pythonVersion == "3.12" then pkgs.python312
    else if pythonVersion == "3.13" then pkgs.python313
    else if pythonVersion == "3.14" then pkgs.python314
    else throw "Unsupported Python version: ${pythonVersion}. Available: 3.10, 3.11, 3.12, 3.13, 3.14";

in customStdenv.mkDerivation {
  name = "${projectName}-shell";

  buildInputs =
    packages.core.essential
    ++ packages.core.search
    ++ packages.core.utils
    ++ [
      # C++ toolchain
      llvm.clang
      llvm.clang-tools
      llvm.lld
      llvm.lldb
      llvm.libcxx
      llvm.libcxx.dev

      # Build tools
      pkgs.cmake
      pkgs.ninja
      pkgs.pkg-config
      pkgs.conan  # C++ package manager

      # Python environment
      pythonPkg  # Base Python interpreter with headers (Python.h)
      pkgs.uv
      pkgs.basedpyright
      pkgs.black
      pkgs.ruff

      # Python packages for hybrid development
      (pythonPkg.withPackages (ps: with ps; [
        pybind11  # Provides pybind11 headers for C++ bindings
        pytest    # Test runner
        ipython   # Interactive shell  
        debugpy   # DAP debugging
        # numpy removed - let uv manage runtime dependencies via requirements.txt
      ]))

      # Testing
      pkgs.gtest
    ]
    ++ extraPackages;

  shellHook = ''
    # Clear any polluting CPLUS_INCLUDE_PATH from the system
    unset CPLUS_INCLUDE_PATH

    echo "🔗 C++ + Python Hybrid Development Environment: ${projectName}"
    echo "   C++ Standard: C++${cppStandard}"
    echo "   LLVM Version: ${llvmVersion}"
    echo "   Python version: ${pythonVersion}"
    echo "   Binding library: pybind11"
    echo ""

    # Note: Virtual environment is managed by direnv's 'layout python'
    # Development tools are provided by Nix (pybind11, numpy, pytest, etc.)

    # Create local Conan profiles with correct compiler version
    if [ ! -f .conan2/profiles/release ] || [ ! -f .conan2/profiles/debug ]; then
      echo "Creating local Conan profiles..."
      mkdir -p .conan2/profiles

      # Create release profile
      cat > .conan2/profiles/release << EOF
[settings]
arch=armv8
build_type=Release
compiler=clang
compiler.cppstd=${cppStandard}
compiler.libcxx=libc++
compiler.version=${llvmVersion}
os=Macos

[conf]
tools.build:exelinkflags=['-fuse-ld=lld']
tools.build:jobs=10
tools.build:sharedlinkflags=['-fuse-ld=lld']
tools.cmake.cmaketoolchain:extra_variables={'CMAKE_EXPORT_COMPILE_COMMANDS': 'ON'}
tools.cmake.cmaketoolchain:generator=Ninja

[buildenv]
CC=${llvm.clang}/bin/clang
CXX=${llvm.clang}/bin/clang++
LD=${llvm.lld}/bin/lld
CMAKE_EXPORT_COMPILE_COMMANDS=ON
EOF

      # Create debug profile
      cat > .conan2/profiles/debug << EOF
[settings]
arch=armv8
build_type=Debug
compiler=clang
compiler.cppstd=${cppStandard}
compiler.libcxx=libc++
compiler.version=${llvmVersion}
os=Macos

[conf]
tools.build:exelinkflags=['-fuse-ld=lld']
tools.build:jobs=10
tools.build:sharedlinkflags=['-fuse-ld=lld']
tools.cmake.cmaketoolchain:extra_variables={'CMAKE_EXPORT_COMPILE_COMMANDS': 'ON'}
tools.cmake.cmaketoolchain:generator=Ninja

[buildenv]
CC=${llvm.clang}/bin/clang
CXX=${llvm.clang}/bin/clang++
LD=${llvm.lld}/bin/lld
CMAKE_EXPORT_COMPILE_COMMANDS=ON
EOF
      echo "✓ Created local Conan profiles (release and debug)"
    fi

    # Set up Conan for C++ dependencies
    if [ ! -f conanfile.txt ]; then
      echo "Creating conanfile.txt with pybind11..."
      cat > conanfile.txt << EOF
[requires]
pybind11/2.11.1

[generators]
CMakeDeps
CMakeToolchain

[options]

[imports]

EOF
    fi

    # Set up build directory for C++ extension
    if [ ! -d build ]; then
      echo "Creating build directory..."
      mkdir -p build
    fi

    echo "📦 Build workflow:"
    echo "  1. Install deps: conan install . --profile=.conan2/profiles/release --output-folder=build --build=missing"
    echo "  2. Configure:    cmake -S . -B build -DCMAKE_TOOLCHAIN_FILE=build/conan_toolchain.cmake"
    echo "  3. Build:        cmake --build build"
    echo "  4. Install:      pip install -e ."
    echo "  5. Test C++:     ./build/tests/test_cpp"
    echo "  6. Test Python:  pytest tests/"
    echo ""
    echo "🧪 Testing:"
    echo "  C++ tests:   ctest --test-dir build"
    echo "  Python tests: pytest"
    echo ""
    echo "✅ Environment ready!"
  '';

  # Environment variables
  CMAKE_CXX_STANDARD = cppStandard;

  # Set CC and CXX to use the selected LLVM version
  CC = "${llvm.clang}/bin/clang";
  CXX = "${llvm.clang}/bin/clang++";

  LLDB_DEBUGSERVER_PATH = "/Applications/Xcode.app/Contents/SharedFrameworks/LLDB.framework/Versions/A/Resources/debugserver";
}