{
  pkgs,
  cppStandard ? "20",  # "11", "14", "17", "20", "23"
  llvmVersion ? "llvmPackages",  # "llvmPackages", "llvmPackages_16", "llvmPackages_17", "llvmPackages_18", "llvmPackages_19"
  extraPackages ? [],
  projectName ? "cpp-dev",
}: let
  llvm = pkgs.${llvmVersion};
in pkgs.mkShell {
  name = "${projectName}-shell";

  buildInputs = [
    # Build tools
    pkgs.conan
    pkgs.cmake
    pkgs.ninja
    pkgs.pkg-config

    # Compiler etc from LLVM set
    llvm.clang
    llvm.clang-tools  # This includes clangd
    llvm.lld
    llvm.lldb
    llvm.libcxx
    llvm.libcxx.dev
  ] ++ extraPackages;

  shellHook = ''
    export LLDB_DEBUGSERVER_PATH=/Applications/Xcode.app/Contents/SharedFrameworks/LLDB.framework/Versions/A/Resources/debugserver

    echo "🔧 C++ Development Environment: ${projectName}"
    echo "C++ Standard: C++${cppStandard}"
    echo "LLVM Version: ${llvmVersion}"

    # Create build directory if CMakeLists.txt exists
    if [ -f CMakeLists.txt ] && [ ! -d build ]; then
      echo "Creating build directory..."
      mkdir -p build
    fi

    # Create default conan profile if it doesn't exist
    if ! conan profile list 2>/dev/null | grep -q default; then
      echo "Creating default Conan profile..."
      conan profile detect
    fi

    # Show workflow tips if in a project
    if [ -f CMakeLists.txt ] && [ -f conanfile.txt ]; then
      echo ""
      echo "📦 Build workflow:"
      echo "  1. conan install . --build=missing"
      echo "  2. cmake --preset conan-release"
      echo "  3. cmake --build --preset conan-release"
    elif [ -f CMakeLists.txt ]; then
      echo ""
      echo "📦 Build workflow (no Conan):"
      echo "  1. cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON"
      echo "  2. cmake --build build"
    fi

    echo "✅ Environment ready!"
  '';
}