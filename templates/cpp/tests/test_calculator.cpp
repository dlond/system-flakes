#include "myproject/calculator.h"
#include <gtest/gtest.h>

using namespace myproject;

class CalculatorTest : public ::testing::Test {
protected:
    Calculator calc;
};

TEST_F(CalculatorTest, InitDefault) {
    EXPECT_DOUBLE_EQ(calc.result(), 0);
}

TEST(CalculatorTestStandalone, InitWithValue) {
    Calculator calc(10);
    EXPECT_DOUBLE_EQ(calc.result(), 10);
}

TEST_F(CalculatorTest, Add) {
    calc.add(5);
    EXPECT_DOUBLE_EQ(calc.result(), 5);
    calc.add(3);
    EXPECT_DOUBLE_EQ(calc.result(), 8);
}

TEST_F(CalculatorTest, Multiply) {
    calc.add(4);  // Start with 4
    calc.multiply(3);
    EXPECT_DOUBLE_EQ(calc.result(), 12);
}

TEST_F(CalculatorTest, Divide) {
    calc.add(20);  // Start with 20
    calc.divide(4);
    EXPECT_DOUBLE_EQ(calc.result(), 5);
}

TEST_F(CalculatorTest, DivideByZeroThrows) {
    calc.add(10);
    EXPECT_THROW(calc.divide(0), std::invalid_argument);
}

TEST_F(CalculatorTest, Chaining) {
    double result = calc.add(2).add(3).multiply(4).add(1).result();
    EXPECT_DOUBLE_EQ(result, 21);  // (0+2+3)*4+1 = 21
}

TEST_F(CalculatorTest, Reset) {
    calc.add(100);
    EXPECT_DOUBLE_EQ(calc.result(), 100);
    calc.reset();
    EXPECT_DOUBLE_EQ(calc.result(), 0);
}

TEST_F(CalculatorTest, ComplexOperation) {
    Calculator calc(100);
    double result = calc.divide(2).add(10).multiply(2).divide(4).result();
    EXPECT_DOUBLE_EQ(result, 30);  // ((100/2)+10)*2/4 = 30
}