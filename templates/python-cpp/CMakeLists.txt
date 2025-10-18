cmake_minimum_required(VERSION 3.20)
project(MyProject 
    VERSION 0.1.0
    DESCRIPTION "Python project with C++ extensions"
    LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Find packages
find_package(pybind11 REQUIRED)
find_package(fmt REQUIRED)
find_package(GTest REQUIRED)

# Find Python
find_package(Python3 COMPONENTS Interpreter Development REQUIRED)

# Enable testing
enable_testing()
include(GoogleTest)

# Core C++ library
add_library(myproject_core
    src/core.cpp
    src/math_ops.cpp
)
target_include_directories(myproject_core PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)
target_link_libraries(myproject_core PUBLIC fmt::fmt)

# Python module
pybind11_add_module(_myproject_ext src/bindings.cpp)
target_link_libraries(_myproject_ext PRIVATE myproject_core)
target_compile_definitions(_myproject_ext PRIVATE VERSION_INFO="${PROJECT_VERSION}")

# Set the output directory for the Python module
set_target_properties(_myproject_ext PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/python/myproject
)

# C++ executable example
add_executable(myproject_cli src/main.cpp)
target_link_libraries(myproject_cli PRIVATE myproject_core)

# Tests
add_subdirectory(tests)