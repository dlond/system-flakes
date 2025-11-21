add_executable(test_HelloWorld test_core.cpp test_calculator.cpp)

if(TEST_FRAMEWORK STREQUAL "gtest")
  find_package(GTest REQUIRED)
  include(GoogleTest)
  target_link_libraries(test_HelloWorld PRIVATE HelloWorld_core GTest::gtest
                                                GTest::gtest_main)
  gtest_discover_tests(test_HelloWorld)
elseif(TEST_FRAMEWORK STREQUAL "catch2")
  find_package(Catch2 3 REQUIRED)
  include(Catch)
  target_link_libraries(test_HelloWorld PRIVATE HelloWorld_core
                                                Catch2::Catch2WithMain)
  catch_discover_tests(test_HelloWorld)
endif()

if(ENABLE_COVERAGE AND CMAKE_BUILD_TYPE STREQUAL "Debug")
  add_compile_options(--coverage)
  add_link_options(--coverage)
endif()
