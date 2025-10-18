cmake_minimum_required(VERSION 3.20)
project(MyProject 
    VERSION 0.1.0
    DESCRIPTION "A C++ project template"
    LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Find packages via Conan
find_package(fmt REQUIRED)
find_package(GTest REQUIRED)

# Enable testing
enable_testing()
include(GoogleTest)

# Main library
add_library(myproject_core
    src/core.cpp
    src/calculator.cpp
)
target_include_directories(myproject_core PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)
target_link_libraries(myproject_core PUBLIC fmt::fmt)

# Main executable
add_executable(myproject src/main.cpp)
target_link_libraries(myproject PRIVATE myproject_core)

# Tests
add_subdirectory(tests)