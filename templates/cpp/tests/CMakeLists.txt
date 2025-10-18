# Test executable
add_executable(test_myproject
    test_core.cpp
    test_calculator.cpp
)

target_link_libraries(test_myproject PRIVATE
    myproject_core
    GTest::gtest
    GTest::gtest_main
)

# Register tests with CTest
gtest_discover_tests(test_myproject)