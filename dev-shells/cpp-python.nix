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
    # macOS-specific debugging setup
    ${if pkgs.stdenv.isDarwin then ''
      export LLDB_DEBUGSERVER_PATH=/Applications/Xcode.app/Contents/SharedFrameworks/LLDB.framework/Versions/A/Resources/debugserver
    '' else ""}

    echo "🔗 C++ + Python Hybrid Development Environment: ${projectName}"
    echo ""
    echo "🔧 C++ Environment:"
    echo "   LLVM Version: ${llvmVersion}"
    echo "   C++ Standard: C++${cppStandard}"
    echo "   Package Manager: conan"
    echo "   Test Framework: gtest"
    echo ""
    echo "🐍 Python Environment:"
    echo "   Python version: ${pythonVersion}"
    echo "   Package manager: uv"
    echo "   Binding library: pybind11 (from Nix)"

    # Note: Virtual environment is managed by direnv's 'layout python'
    # Build tools (pybind11) are provided by Nix
    # Runtime dependencies (numpy, etc.) are managed by uv

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
      echo "Creating conanfile.txt for C++ dependencies..."
      cat > conanfile.txt << EOF
[requires]
gtest/1.14.0
# pybind11 is provided by Nix to ensure compatibility with Python

[generators]
CMakeDeps
CMakeToolchain

[options]

[imports]

EOF
    fi

    # Register Jupyter kernel for this project
    if ! jupyter kernelspec list 2>/dev/null | grep -q "${projectName}"; then
      echo "Registering Jupyter kernel..."
      python -m ipykernel install --user --name="${projectName}" --display-name="${projectName} (Python ${pythonVersion})"
    fi

    # Set up build directory for C++ extension
    if [ ! -d build ]; then
      echo "Creating build directory..."
      mkdir -p build
    fi

    echo ""
    echo "📦 C++ Build workflow:"
    echo "  1. Install deps:     conan install . --profile=.conan2/profiles/release --output-folder=build --build=missing"
    echo "  2. Configure:        cmake -S . -B build -DCMAKE_TOOLCHAIN_FILE=build/conan_toolchain.cmake"
    echo "  3. Build:            cmake --build build"
    echo "  4. Install module:   pip install -e ."
    echo ""
    echo "🐍 Python workflow:"
    echo "  1. Add dependencies: echo 'numpy>=1.20.0' >> requirements.txt"
    echo "  2. Install packages: uv pip install -r requirements.txt"
    echo "  3. Run Python:       python"
    echo "  4. Import module:    import ${projectName//-/_}"
    echo ""
    echo "🧪 Testing:"
    echo "  C++ tests:    ctest --test-dir build"
    echo "  Python tests: pytest tests/"
    echo "  All tests:    ctest --test-dir build && pytest"
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