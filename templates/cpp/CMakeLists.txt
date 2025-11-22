cmake_minimum_required(VERSION 3.20)
project(
  hello_cpp
  VERSION 0.1.0
  DESCRIPTION "A c++ project template"
  LANGUAGES CXX)

# C++ Standard
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
add_custom_target(
  link_latest_compile_commands ALL
  COMMAND
    ${CMAKE_COMMAND} -E create_symlink ${CMAKE_BINARY_DIR}/compile_commands.json
    ${CMAKE_SOURCE_DIR}/compile_commands.json
  DEPENDS ${CMAKE_BINARY_DIR}/compile_commands.json)

find_program(CCACHE_PROGRAM ccache)
if(CCACHE_PROGRAM)
  message(STATUS "Enabling ccache: ${CCACHE_PROGRAM}")
  set(CMAKE_C_COMPILER_LAUNCHER "${CCACHE_PROGRAM}")
  set(CMAKE_CXX_COMPILER_LAUNCHER "${CCACHE_PROGRAM}")
endif()

find_package(fmt REQUIRED)

add_library(hello_core src/core.cpp src/calculator.cpp)
target_include_directories(
  hello_core PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
                    $<INSTALL_INTERFACE:include>)
target_link_libraries(hello_core PUBLIC fmt::fmt)

# Main executable
add_executable(hello_app src/main.cpp)
target_link_libraries(hello_app PRIVATE hello_core)

enable_testing()
add_subdirectory(tests)
