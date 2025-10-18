# C++ tests
add_executable(test_cpp_core
    test_cpp_core.cpp
)

target_link_libraries(test_cpp_core PRIVATE
    myproject_core
    GTest::gtest
    GTest::gtest_main
)

# Register tests with CTest
gtest_discover_tests(test_cpp_core)