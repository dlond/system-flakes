#include "myproject/core.h"
#include <gtest/gtest.h>
#include <vector>

using namespace myproject;

// Test greet function
TEST(CoreTest, GreetBasic) {
    EXPECT_EQ(greet("World"), "Hello, World!");
}

TEST(CoreTest, GreetWithName) {
    EXPECT_EQ(greet("Alice"), "Hello, Alice!");
    EXPECT_EQ(greet("Bob"), "Hello, Bob!");
}

TEST(CoreTest, GreetEmptyThrows) {
    EXPECT_THROW(greet(""), std::invalid_argument);
}

// Test add_numbers function
TEST(CoreTest, AddIntegers) {
    EXPECT_DOUBLE_EQ(add_numbers(2, 3), 5);
}

TEST(CoreTest, AddFloats) {
    EXPECT_DOUBLE_EQ(add_numbers(2.5, 3.5), 6.0);
}

TEST(CoreTest, AddNegative) {
    EXPECT_DOUBLE_EQ(add_numbers(-1, 1), 0);
    EXPECT_DOUBLE_EQ(add_numbers(-5, -3), -8);
}

// Test calculate_mean function
TEST(CoreTest, MeanOfVector) {
    std::vector<double> values = {1, 2, 3, 4, 5};
    EXPECT_DOUBLE_EQ(calculate_mean(values), 3.0);
}

TEST(CoreTest, MeanOfSingleValue) {
    std::vector<double> values = {42.0};
    EXPECT_DOUBLE_EQ(calculate_mean(values), 42.0);
}

TEST(CoreTest, MeanOfEmptyVector) {
    std::vector<double> values;
    EXPECT_DOUBLE_EQ(calculate_mean(values), 0.0);
}

// Parameterized test
class AddParameterizedTest : public ::testing::TestWithParam<std::tuple<double, double, double>> {};

TEST_P(AddParameterizedTest, AddNumbers) {
    auto [a, b, expected] = GetParam();
    EXPECT_DOUBLE_EQ(add_numbers(a, b), expected);
}

INSTANTIATE_TEST_SUITE_P(
    AddTestSuite,
    AddParameterizedTest,
    ::testing::Values(
        std::make_tuple(1, 1, 2),
        std::make_tuple(0, 0, 0),
        std::make_tuple(100, 200, 300),
        std::make_tuple(-50, 50, 0)
    )
);