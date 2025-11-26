add_executable(test_${CMAKE_PROJECT_NAME} test_core.cpp test_calculator.cpp)

if(DEFINED ENV{TEST_FRAMEWORK})
  set(TEST_FRAMEWORK $ENV{TEST_FRAMEWORK})
else()
  set(TEST_FRAMEWORK "gtest")
endif()

if(TEST_FRAMEWORK STREQUAL "gtest")
  message(STATUS "Enabling gtest")
  find_package(GTest REQUIRED)
  include(GoogleTest)
  target_link_libraries(
    test_${CMAKE_PROJECT_NAME} PRIVATE ${CMAKE_PROJECT_NAME}_core GTest::gtest
                                       GTest::gtest_main)
  gtest_discover_tests(test_${CMAKE_PROJECT_NAME})
elseif(TEST_FRAMEWORK STREQUAL "catch2")
  message(STATUS "Enabling catch2")
  find_package(Catch2 3 REQUIRED)
  include(Catch)
  target_link_libraries(
    test_${CMAKE_PROJECT_NAME} PRIVATE ${CMAKE_PROJECT_NAME}_core
                                       Catch2::Catch2WithMain)
  catch_discover_tests(test_${CMAKE_PROJECT_NAME})
endif()

if(ENABLE_COVERAGE AND CMAKE_BUILD_TYPE STREQUAL "Debug")
  add_compile_options(--coverage)
  add_link_options(--coverage)
endif()
