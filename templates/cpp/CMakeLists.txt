cmake_minimum_required(VERSION 3.20)
project(
  MyProject
  VERSION 0.1.0
  DESCRIPTION "A C++ project template"
  LANGUAGES CXX)

# ============================================================================
# Read configuration from environment (set by flake.nix) with fallbacks
# ============================================================================

# C++ Standard
if(DEFINED ENV{CMAKE_CXX_STANDARD})
  set(CMAKE_CXX_STANDARD $ENV{CMAKE_CXX_STANDARD})
else()
  set(CMAKE_CXX_STANDARD 20)
endif()
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Export compile commands
if(DEFINED ENV{CMAKE_EXPORT_COMPILE_COMMANDS})
  set(CMAKE_EXPORT_COMPILE_COMMANDS $ENV{CMAKE_EXPORT_COMPILE_COMMANDS})
else()
  set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
endif()

# Build type (if not already set by preset)
if(NOT CMAKE_BUILD_TYPE AND DEFINED ENV{CMAKE_BUILD_TYPE})
  set(CMAKE_BUILD_TYPE $ENV{CMAKE_BUILD_TYPE})
endif()

# Shared/static libraries
if(DEFINED ENV{BUILD_SHARED_LIBS})
  set(BUILD_SHARED_LIBS $ENV{BUILD_SHARED_LIBS})
endif()

# ============================================================================
# Compiler flags based on environment configuration
# ============================================================================

# Helper function to get env var with default
function(get_env_bool var default)
  if(DEFINED ENV{${var}})
    set(${var} $ENV{${var}} PARENT_SCOPE)
  else()
    set(${var} ${default} PARENT_SCOPE)
  endif()
endfunction()

get_env_bool(ENABLE_LTO OFF)
get_env_bool(ENABLE_EXCEPTIONS ON)
get_env_bool(ENABLE_RTTI ON)
get_env_bool(ENABLE_SANITIZERS OFF)
get_env_bool(MARCH_NATIVE OFF)

# Optimization level
if(DEFINED ENV{OPTIMIZATION_LEVEL})
  set(OPTIMIZATION_LEVEL $ENV{OPTIMIZATION_LEVEL})
else()
  set(OPTIMIZATION_LEVEL "2")
endif()

# Warning level
if(DEFINED ENV{WARNING_LEVEL})
  set(WARNING_LEVEL $ENV{WARNING_LEVEL})
else()
  set(WARNING_LEVEL "all")
endif()

# Compiler-specific flags
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
  # Warning flags
  if(WARNING_LEVEL STREQUAL "all")
    add_compile_options(-Wall -Wextra)
  elseif(WARNING_LEVEL STREQUAL "extra")
    add_compile_options(-Wall -Wextra -Wpedantic)
  elseif(WARNING_LEVEL STREQUAL "default")
    add_compile_options(-Wall)
  endif()

  # Release optimization
  if(CMAKE_BUILD_TYPE STREQUAL "Release")
    add_compile_options(-O${OPTIMIZATION_LEVEL})

    if(MARCH_NATIVE)
      add_compile_options(-march=native -mtune=native)
    endif()

    if(NOT ENABLE_EXCEPTIONS)
      add_compile_options(-fno-exceptions)
    endif()

    if(NOT ENABLE_RTTI)
      add_compile_options(-fno-rtti)
    endif()

    # Link-time optimization
    if(ENABLE_LTO)
      set(CMAKE_INTERPROCEDURAL_OPTIMIZATION TRUE)
      add_compile_options(-flto)
    endif()
  endif()

  # Debug flags
  if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    add_compile_options(-O0 -g3)

    if(ENABLE_SANITIZERS)
      add_compile_options(-fsanitize=address -fsanitize=undefined)
      add_link_options(-fsanitize=address -fsanitize=undefined)
    endif()
  endif()
endif()

# ============================================================================
# Dependencies
# ============================================================================

# Find packages via Conan
find_package(fmt REQUIRED)

# ============================================================================
# Testing configuration
# ============================================================================

get_env_bool(ENABLE_TESTING ON)
get_env_bool(ENABLE_COVERAGE OFF)

if(ENABLE_TESTING)
  enable_testing()

  # Determine test framework from environment
  if(DEFINED ENV{TEST_FRAMEWORK})
    set(TEST_FRAMEWORK $ENV{TEST_FRAMEWORK})
  else()
    set(TEST_FRAMEWORK "gtest")
  endif()

  # Find test framework
  if(TEST_FRAMEWORK STREQUAL "gtest")
    find_package(GTest REQUIRED)
    include(GoogleTest)
  elseif(TEST_FRAMEWORK STREQUAL "catch2")
    find_package(Catch2 3 REQUIRED)
    include(Catch)
  endif()

  if(ENABLE_COVERAGE AND CMAKE_BUILD_TYPE STREQUAL "Debug")
    add_compile_options(--coverage)
    add_link_options(--coverage)
  endif()
endif()

# ============================================================================
# Project targets
# ============================================================================

# Main library
add_library(myproject_core src/core.cpp src/calculator.cpp)
target_include_directories(
  myproject_core PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
                        $<INSTALL_INTERFACE:include>)
target_link_libraries(myproject_core PUBLIC fmt::fmt)

# Main executable
add_executable(myproject src/main.cpp)
target_link_libraries(myproject PRIVATE myproject_core)

# ============================================================================
# Tests
# ============================================================================

if(ENABLE_TESTING)
  add_subdirectory(tests)
endif()

# ============================================================================
# Development tools
# ============================================================================

# Bring latest compile commands to project root
if(CMAKE_EXPORT_COMPILE_COMMANDS)
  add_custom_target(
    copy_compile_commands ALL
    COMMAND
      ${CMAKE_COMMAND} -E copy_if_different
      ${CMAKE_BINARY_DIR}/compile_commands.json
      ${CMAKE_SOURCE_DIR}/compile_commands.json
    DEPENDS ${CMAKE_BINARY_DIR}/compile_commands.json)
endif()

# Print configuration summary
message(STATUS "")
message(STATUS "=== Build Configuration (from flake.nix) ===")
message(STATUS "C++ Standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "Build Type: ${CMAKE_BUILD_TYPE}")
message(STATUS "Testing: ${ENABLE_TESTING}")
if(ENABLE_TESTING)
  message(STATUS "Test Framework: ${TEST_FRAMEWORK}")
  message(STATUS "Coverage: ${ENABLE_COVERAGE}")
endif()
message(STATUS "LTO: ${ENABLE_LTO}")
message(STATUS "Exceptions: ${ENABLE_EXCEPTIONS}")
message(STATUS "RTTI: ${ENABLE_RTTI}")
message(STATUS "Sanitizers: ${ENABLE_SANITIZERS}")
message(STATUS "Warning Level: ${WARNING_LEVEL}")
message(STATUS "Optimization: -O${OPTIMIZATION_LEVEL}")
message(STATUS "March Native: ${MARCH_NATIVE}")
message(STATUS "==========================================")
message(STATUS "")