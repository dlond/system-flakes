{
  pkgs,
  projectName ? "cpp-dev",
  # Version overrides
  llvmVersion ? "20",                      # LLVM version: 9, 12-21
  cppStandard ? "20",                      # C++ standard: 11, 14, 17, 20, 23
  packageManager ? "conan",                # Package manager: "conan", "vcpkg", "cpm", "none"
  testFramework ? "gtest",                 # Test framework: "gtest", "catch2", "doctest", "boost", "none"
  # Optional features
  withBazel ? false,
  withDocs ? false,
  withAnalysis ? false,
  # Extra packages
  extraPackages ? [],
}: let
  packages = import ../lib/packages.nix {
    inherit pkgs llvmVersion;
  };

  # Get the LLVM package for this shell using string concatenation
  llvm = pkgs."llvmPackages_${llvmVersion}" or pkgs.llvmPackages;

  # Use custom stdenv with the selected LLVM
  customStdenv = pkgs.overrideCC pkgs.stdenv llvm.clang;

  # Get C++ packages with our configuration
  cppPackages = packages.cpp.packages {
    inherit llvmVersion cppStandard packageManager testFramework
            withBazel withDocs withAnalysis;
  };

in customStdenv.mkDerivation {
  name = "${projectName}-shell";

  buildInputs =
    packages.core.essential
    ++ packages.core.search
    ++ packages.core.utils
    ++ cppPackages
    ++ extraPackages;

  shellHook = ''
    export LLDB_DEBUGSERVER_PATH=/Applications/Xcode.app/Contents/SharedFrameworks/LLDB.framework/Versions/A/Resources/debugserver

    # Clear any polluting CPLUS_INCLUDE_PATH from the system
    unset CPLUS_INCLUDE_PATH

    echo "🔧 C++ Development Environment: ${projectName}"
    echo "   LLVM Version: ${llvmVersion}"
    echo "   C++ Standard: C++${cppStandard}"
    echo "   Package Manager: ${packageManager}"
    echo "   Test Framework: ${testFramework}"

    # Show optional features if enabled
    ${if withBazel then "echo \"   ✓ Bazel support enabled\"" else ""}
    ${if withDocs then "echo \"   ✓ Documentation tools enabled\"" else ""}
    ${if withAnalysis then "echo \"   ✓ Analysis tools enabled\"" else ""}

    # Package manager specific setup
    ${if packageManager == "conan" then ''
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

      # Create a basic conanfile.txt if none exists
      if [ ! -f conanfile.txt ] && [ ! -f conanfile.py ]; then
        echo "Creating basic conanfile.txt..."
        cat > conanfile.txt << 'EOF'
[requires]
# Add your dependencies here, for example:
# fmt/10.1.0
# spdlog/1.12.0
${if testFramework == "gtest" then "gtest/1.14.0" else if testFramework == "catch2" then "catch2/3.4.0" else if testFramework == "doctest" then "doctest/2.4.11" else "# ${testFramework}/version"}

[generators]
CMakeDeps
CMakeToolchain

[layout]
cmake_layout

[options]
# Add package options here if needed

[imports]
# Import files from dependencies if needed
EOF
        echo "✓ Created conanfile.txt"
      fi
    '' else ""}

    ${if packageManager == "vcpkg" then ''
      # Create vcpkg.json if it doesn't exist
      if [ ! -f vcpkg.json ]; then
        echo "Creating basic vcpkg.json..."
        # vcpkg requires lowercase package names with only alphanumeric+hyphens
        VCPKG_NAME=$(echo "${projectName}" | tr '[:upper:]' '[:lower:]' | tr '_' '-')
        cat > vcpkg.json << EOF
{
  "name": "$VCPKG_NAME",
  "version": "0.1.0",
  "builtin-baseline": "c82f74667287d3dc386bce81e44964370c91a289",
  "dependencies": [
${if testFramework == "gtest" then ''    "gtest"'' else if testFramework == "catch2" then ''    "catch2"'' else ""}
  ]
}
EOF
        echo "✓ Created vcpkg.json"
      fi
    '' else ""}

    # Create build directory if using non-Conan build and CMakeLists.txt exists
    ${if packageManager != "conan" then ''
      if [ -f CMakeLists.txt ] && [ ! -d build ]; then
        echo "Creating build directory..."
        mkdir -p build
      fi
    '' else ""}

    # Show workflow tips based on what's in the project
    if [ -f CMakeLists.txt ]; then
      echo ""
      echo "📦 Build workflow:"

      ${if packageManager == "conan" then ''
        echo "  1. conan install . --build=missing"
        echo "  2. cmake --preset conan-release"
        echo "  3. cmake --build --preset conan-release"
      '' else if packageManager == "vcpkg" then ''
        echo "  1. vcpkg install"
        echo "  2. cmake -S . -B build -DCMAKE_TOOLCHAIN_FILE=$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake"
        echo "  3. cmake --build build"
      '' else ''
        echo "  1. cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_CXX_STANDARD=${cppStandard}"
        echo "  2. cmake --build build"
      ''}

      ${if testFramework != "none" then ''
        echo ""
        echo "🧪 Testing:"
        echo "  ctest --test-dir build"
        ${if packageManager == "conan" then ''echo "  # Or: ctest --preset conan-release"'' else ""}
      '' else ""}
    elif [ -f Makefile ]; then
      echo ""
      echo "📦 Build workflow:"
      echo "  make"
    ${if withBazel then ''
    elif [ -f BUILD ] || [ -f BUILD.bazel ]; then
      echo ""
      echo "📦 Build workflow:"
      echo "  bazel build //..."
      echo "  bazel test //..."
    '' else ""}
    else
      echo ""
      echo "💡 No build file detected. Create one of:"
      echo "  - CMakeLists.txt (recommended)"
      ${if withBazel then "echo \"  - BUILD.bazel (Bazel)\"" else ""}
      echo "  - Makefile"
    fi

    echo ""
    echo "✅ Environment ready!"
  '';

  # Environment variables
  CMAKE_CXX_STANDARD = cppStandard;

  # Set CC and CXX to use the selected LLVM version
  CC = "${llvm.clang}/bin/clang";
  CXX = "${llvm.clang}/bin/clang++";
}