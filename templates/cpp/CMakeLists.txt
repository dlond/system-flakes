cmake_minimum_required(VERSION 3.20)
project(
  __PROJECT_NAME__
  VERSION 0.1.0
  DESCRIPTION "A C++ project template"
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

add_library(${CMAKE_PROJECT_NAME}_lib src/core.cpp src/calculator.cpp)
target_include_directories(
  ${CMAKE_PROJECT_NAME}_lib
  PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
         $<INSTALL_INTERFACE:include>)
target_link_libraries(${CMAKE_PROJECT_NAME}_lib PUBLIC fmt::fmt)

# Main executable
add_executable(${CMAKE_PROJECT_NAME}_app src/main.cpp)
target_link_libraries(${CMAKE_PROJECT_NAME}_app
                      PRIVATE ${CMAKE_PROJECT_NAME}_lib)

enable_testing()
add_subdirectory(tests)
