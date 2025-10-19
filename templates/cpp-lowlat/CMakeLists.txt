cmake_minimum_required(VERSION 3.23)
project(lowlat_trading VERSION 1.0.0 LANGUAGES CXX)

# C++23 for latest features
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Conan package manager setup
list(APPEND CMAKE_PREFIX_PATH ${CMAKE_BINARY_DIR})
list(APPEND CMAKE_MODULE_PATH ${CMAKE_BINARY_DIR})

# Compiler-specific optimizations
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    add_compile_options(
        -Wall -Wextra -Wpedantic
        -Wno-unused-parameter
        $<$<CONFIG:Release>:-O3>
        $<$<CONFIG:Release>:-march=native>
        $<$<CONFIG:Release>:-mtune=native>
        $<$<CONFIG:Release>:-flto>
        $<$<CONFIG:Release>:-fno-exceptions>  # Disable exceptions for speed
        $<$<CONFIG:Debug>:-O0>
        $<$<CONFIG:Debug>:-g3>
        $<$<CONFIG:Debug>:-fsanitize=address>
        $<$<CONFIG:Debug>:-fsanitize=undefined>
    )
    
    # Link-time optimization
    if(CMAKE_BUILD_TYPE STREQUAL "Release")
        set(CMAKE_INTERPROCEDURAL_OPTIMIZATION TRUE)
    endif()
endif()

# Find packages (from Conan)
find_package(Threads REQUIRED)
find_package(benchmark REQUIRED)
find_package(GTest REQUIRED)
find_package(Boost REQUIRED)
find_package(fmt REQUIRED)
find_package(spdlog REQUIRED)

# Main library
add_library(trading_core STATIC
    src/order_book.cpp
    src/matching_engine.cpp
    src/memory_pool.cpp
    src/lock_free_queue.cpp
)

target_include_directories(trading_core PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

target_link_libraries(trading_core PUBLIC
    Threads::Threads
)

# Main executable
add_executable(trading_engine
    src/main.cpp
)

target_link_libraries(trading_engine PRIVATE
    trading_core
)

# Benchmarks
if(benchmark_FOUND)
    add_executable(bench_orderbook
        bench/bench_orderbook.cpp
    )
    target_link_libraries(bench_orderbook PRIVATE
        trading_core
        benchmark::benchmark
    )
endif()

# Tests
if(GTest_FOUND)
    enable_testing()
    add_executable(test_trading
        tests/test_order_book.cpp
        tests/test_matching_engine.cpp
    )
    target_link_libraries(test_trading PRIVATE
        trading_core
        GTest::gtest_main
    )
    include(GoogleTest)
    gtest_discover_tests(test_trading)
endif()

# Installation
install(TARGETS trading_core trading_engine
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
)

install(DIRECTORY include/ DESTINATION include)