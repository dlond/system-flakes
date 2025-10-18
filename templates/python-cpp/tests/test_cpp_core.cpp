#include "myproject/core.h"
#include "myproject/math_ops.h"
#include <gtest/gtest.h>
#include <vector>

using namespace myproject;

// Core tests
TEST(CoreTest, Greet) {
    EXPECT_EQ(greet("World"), "Hello, World!");
    EXPECT_THROW(greet(""), std::invalid_argument);
}

TEST(CoreTest, AddNumbers) {
    EXPECT_DOUBLE_EQ(add_numbers(2.5, 3.5), 6.0);
}

// Vector operations tests
TEST(MathOpsTest, AddVectors) {
    std::vector<double> a = {1, 2, 3};
    std::vector<double> b = {4, 5, 6};
    auto result = add_vectors(a, b);
    
    ASSERT_EQ(result.size(), 3);
    EXPECT_DOUBLE_EQ(result[0], 5);
    EXPECT_DOUBLE_EQ(result[1], 7);
    EXPECT_DOUBLE_EQ(result[2], 9);
}

TEST(MathOpsTest, AddVectorsDifferentSize) {
    std::vector<double> a = {1, 2};
    std::vector<double> b = {3, 4, 5};
    EXPECT_THROW(add_vectors(a, b), std::invalid_argument);
}

TEST(MathOpsTest, DotProduct) {
    std::vector<double> a = {1, 2, 3};
    std::vector<double> b = {4, 5, 6};
    EXPECT_DOUBLE_EQ(dot_product(a, b), 32);  // 1*4 + 2*5 + 3*6
}

TEST(MathOpsTest, VectorNorm) {
    std::vector<double> v = {3, 4};  // 3-4-5 triangle
    EXPECT_DOUBLE_EQ(vector_norm(v), 5.0);
}

// Matrix tests
TEST(MatrixTest, Construction) {
    Matrix m1(2, 3);
    EXPECT_EQ(m1.rows(), 2);
    EXPECT_EQ(m1.cols(), 3);
    
    Matrix m2({{1, 2}, {3, 4}});
    EXPECT_EQ(m2.rows(), 2);
    EXPECT_EQ(m2.cols(), 2);
    EXPECT_DOUBLE_EQ(m2.at(0, 0), 1);
    EXPECT_DOUBLE_EQ(m2.at(1, 1), 4);
}

TEST(MatrixTest, Addition) {
    Matrix m1({{1, 2}, {3, 4}});
    Matrix m2({{5, 6}, {7, 8}});
    Matrix result = m1 + m2;
    
    EXPECT_DOUBLE_EQ(result.at(0, 0), 6);
    EXPECT_DOUBLE_EQ(result.at(0, 1), 8);
    EXPECT_DOUBLE_EQ(result.at(1, 0), 10);
    EXPECT_DOUBLE_EQ(result.at(1, 1), 12);
}

TEST(MatrixTest, ScalarMultiplication) {
    Matrix m({{1, 2}, {3, 4}});
    Matrix result = m * 2;
    
    EXPECT_DOUBLE_EQ(result.at(0, 0), 2);
    EXPECT_DOUBLE_EQ(result.at(0, 1), 4);
    EXPECT_DOUBLE_EQ(result.at(1, 0), 6);
    EXPECT_DOUBLE_EQ(result.at(1, 1), 8);
}