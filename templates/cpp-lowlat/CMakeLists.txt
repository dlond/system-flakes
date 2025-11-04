cmake_minimum_required(VERSION 3.23)
project(
  lowlat_trading
  VERSION 1.0.0
  LANGUAGES CXX)

# ============================================================================
# Read configuration from environment (set by flake.nix) with fallbacks
# ============================================================================

# C++ Standard
if(DEFINED ENV{CMAKE_CXX_STANDARD})
  set(CMAKE_CXX_STANDARD $ENV{CMAKE_CXX_STANDARD})
else()
  set(CMAKE_CXX_STANDARD 23)
endif()
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Export compile commands (always ON for LSP support)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Note: Build type is set by Conan presets
# Note: Shared/static libraries are configured via Conan

# ============================================================================
# Helper functions
# ============================================================================

# Helper function to get env var with default
function(get_env_bool var default)
  if(DEFINED ENV{${var}})
    set(${var}
        $ENV{${var}}
        PARENT_SCOPE)
  else()
    set(${var}
        ${default}
        PARENT_SCOPE)
  endif()
endfunction()

# ============================================================================
# Read performance-specific configuration
# ============================================================================

get_env_bool(ENABLE_LTO ON)
get_env_bool(USE_THIN_LTO ON)
get_env_bool(ENABLE_EXCEPTIONS OFF)
get_env_bool(ENABLE_RTTI OFF)
get_env_bool(ENABLE_SANITIZERS OFF)
get_env_bool(MARCH_NATIVE ON)
get_env_bool(ENABLE_FAST_MATH OFF)
get_env_bool(ALIGN_FOR_CACHE ON)
get_env_bool(ENABLE_BENCHMARKS ON)

# Optimization level
if(DEFINED ENV{OPTIMIZATION_LEVEL})
  set(OPTIMIZATION_LEVEL $ENV{OPTIMIZATION_LEVEL})
else()
  set(OPTIMIZATION_LEVEL "3")
endif()

# Warning level
if(DEFINED ENV{WARNING_LEVEL})
  set(WARNING_LEVEL $ENV{WARNING_LEVEL})
else()
  set(WARNING_LEVEL "extra")
endif()

# ============================================================================
# Conan package manager setup
# ============================================================================

list(APPEND CMAKE_PREFIX_PATH ${CMAKE_BINARY_DIR})
list(APPEND CMAKE_MODULE_PATH ${CMAKE_BINARY_DIR})

# ============================================================================
# Compiler-specific optimizations
# ============================================================================

if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
  # Warning flags
  if(WARNING_LEVEL STREQUAL "all")
    add_compile_options(-Wall -Wextra)
  elseif(WARNING_LEVEL STREQUAL "extra")
    add_compile_options(-Wall -Wextra -Wpedantic)
  elseif(WARNING_LEVEL STREQUAL "default")
    add_compile_options(-Wall)
  endif()

  # Suppress specific warnings for performance code
  add_compile_options(-Wno-unused-parameter)

  # Release optimization
  if(CMAKE_BUILD_TYPE STREQUAL "Release" OR CMAKE_BUILD_TYPE STREQUAL
                                            "RelWithDebInfo")
    add_compile_options(-O${OPTIMIZATION_LEVEL})

    if(MARCH_NATIVE)
      add_compile_options(-march=native -mtune=native)
    endif()

    if(NOT ENABLE_EXCEPTIONS)
      add_compile_options(-fno-exceptions)
      add_definitions(-DBOOST_NO_EXCEPTIONS)
    endif()

    if(NOT ENABLE_RTTI)
      add_compile_options(-fno-rtti)
      add_definitions(-DBOOST_NO_RTTI)
    endif()

    if(ENABLE_FAST_MATH)
      add_compile_options(-ffast-math)
    endif()

    # Link-time optimization
    if(ENABLE_LTO)
      set(CMAKE_INTERPROCEDURAL_OPTIMIZATION TRUE)
      if(USE_THIN_LTO)
        add_compile_options(-flto=thin)
        add_link_options(-flto=thin)
      else()
        add_compile_options(-flto)
        add_link_options(-flto)
      endif()
    endif()

    # Additional performance flags
    add_compile_options(-fomit-frame-pointer -fstrict-aliasing
                        -fno-stack-protector)
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
# Cache-line alignment definitions
# ============================================================================

if(ALIGN_FOR_CACHE)
  add_definitions(-DCACHE_LINE_SIZE=64)
  add_definitions(-DALIGN_FOR_CACHE)
endif()

# ============================================================================
# Dependencies
# ============================================================================

# Find packages (from Conan)
find_package(Threads REQUIRED)
find_package(Boost REQUIRED)
find_package(fmt REQUIRED)
find_package(spdlog REQUIRED)

# ============================================================================
# Testing and benchmarking configuration
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
endif()

if(ENABLE_BENCHMARKS)
  find_package(benchmark REQUIRED)
endif()

# ============================================================================
# Main library
# ============================================================================

add_library(trading_core STATIC src/order_book.cpp src/matching_engine.cpp
                                src/memory_pool.cpp src/lock_free_queue.cpp)

target_include_directories(
  trading_core PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
                      $<INSTALL_INTERFACE:include>)

target_link_libraries(trading_core PUBLIC Threads::Threads Boost::boost
                                          fmt::fmt spdlog::spdlog)

# Apply cache-line alignment to the library
if(ALIGN_FOR_CACHE)
  target_compile_definitions(trading_core PUBLIC CACHE_LINE_SIZE=64
                                                 ALIGN_FOR_CACHE)
endif()

# ============================================================================
# Main executable
# ============================================================================

add_executable(trading_engine src/main.cpp)
target_link_libraries(trading_engine PRIVATE trading_core)

# ============================================================================
# Benchmarks
# ============================================================================

if(ENABLE_BENCHMARKS AND benchmark_FOUND)
  add_executable(bench_orderbook bench/bench_orderbook.cpp)
  target_link_libraries(bench_orderbook PRIVATE trading_core
                                                benchmark::benchmark)

  # Ensure benchmarks are built with maximum optimization
  if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    set_target_properties(bench_orderbook PROPERTIES COMPILE_FLAGS "-O3")
  endif()
endif()

# ============================================================================
# Tests
# ============================================================================

if(ENABLE_TESTING AND GTest_FOUND)
  add_executable(test_trading tests/test_order_book.cpp
                              tests/test_matching_engine.cpp)
  target_link_libraries(test_trading PRIVATE trading_core GTest::gtest_main)

  include(GoogleTest)
  gtest_discover_tests(test_trading)
endif()

# ============================================================================
# Documentation
# ============================================================================

get_env_bool(ENABLE_DOCS OFF)

if(ENABLE_DOCS)
  find_package(Doxygen REQUIRED dot)
  find_package(Sphinx REQUIRED)

  if(DOXYGEN_FOUND)
    # Configure Doxyfile
    set(DOXYGEN_INPUT_DIR ${CMAKE_SOURCE_DIR})
    set(DOXYGEN_OUTPUT_DIR ${CMAKE_CURRENT_BINARY_DIR}/docs/doxygen)
    configure_file(${CMAKE_SOURCE_DIR}/docs/Doxyfile.in
                   ${CMAKE_CURRENT_BINARY_DIR}/docs/Doxyfile @ONLY)

    # Configure Sphinx
    configure_file(${CMAKE_SOURCE_DIR}/docs/conf.py.in
                   ${CMAKE_CURRENT_BINARY_DIR}/docs/conf.py @ONLY)

    # Copy other documentation files
    file(COPY ${CMAKE_SOURCE_DIR}/docs/index.rst
         DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/docs)

    # Create docs target
    add_custom_target(
      docs
      COMMAND ${DOXYGEN_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/docs/Doxyfile
      COMMAND sphinx-build -b html ${CMAKE_CURRENT_BINARY_DIR}/docs
              ${CMAKE_CURRENT_BINARY_DIR}/docs/html
      WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
      COMMENT "Generating documentation with Doxygen and Sphinx"
      VERBATIM)

    message(STATUS "Documentation: ON (target: docs)")
    message(
      STATUS "  Build with: cmake --build ${CMAKE_BINARY_DIR} --target docs")
    message(
      STATUS "  View at: ${CMAKE_CURRENT_BINARY_DIR}/docs/html/index.html")
  else()
    message(WARNING "Doxygen not found, documentation target not created")
  endif()
else()
  message(STATUS "Documentation: OFF (set ENABLE_DOCS=ON to enable)")
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

# ============================================================================
# Installation
# ============================================================================

install(
  TARGETS trading_core trading_engine
  LIBRARY DESTINATION lib
  ARCHIVE DESTINATION lib
  RUNTIME DESTINATION bin)

install(DIRECTORY include/ DESTINATION include)

if(ENABLE_BENCHMARKS AND benchmark_FOUND)
  install(TARGETS bench_orderbook RUNTIME DESTINATION bin)
endif()

# ============================================================================
# Print configuration summary
# ============================================================================

message(STATUS "")
message(STATUS "=== Low-Latency Build Configuration (from flake.nix) ===")
message(STATUS "C++ Standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "Build Type: ${CMAKE_BUILD_TYPE}")
message(STATUS "Optimization: -O${OPTIMIZATION_LEVEL}")
message(STATUS "LTO: ${ENABLE_LTO} (${USE_THIN_LTO})")
message(STATUS "Exceptions: ${ENABLE_EXCEPTIONS}")
message(STATUS "RTTI: ${ENABLE_RTTI}")
message(STATUS "March Native: ${MARCH_NATIVE}")
message(STATUS "Fast Math: ${ENABLE_FAST_MATH}")
message(STATUS "Cache Alignment: ${ALIGN_FOR_CACHE}")
message(STATUS "Testing: ${ENABLE_TESTING}")
message(STATUS "Benchmarks: ${ENABLE_BENCHMARKS}")
message(STATUS "Sanitizers: ${ENABLE_SANITIZERS}")
message(STATUS "Warning Level: ${WARNING_LEVEL}")
message(STATUS "========================================================")
message(STATUS "")
