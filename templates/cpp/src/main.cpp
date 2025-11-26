#include "__PROJECT_NAME__/calculator.h"
#include "__PROJECT_NAME__/core.h"
#include <cstdio>
#include <exception>
#include <fmt/base.h>
#include <fmt/core.h>
#include <vector>

int main() {
  using namespace __PROJECT_NAME__;

  // Demonstrate greeting
  try {
    fmt::print("{}\n", greet("World"));
  } catch (const std::exception &e) {
    fmt::print(stderr, "Error: {}\n", e.what());
  }

  // Demonstrate calculator
  Calculator calc(10);
  double result = calc.add(5).multiply(2).divide(3).result();
  fmt::print("Calculator result: {:.2f}\n", result);

  // Demonstrate mean calculation
  std::vector<double> numbers = {1.0, 2.0, 3.0, 4.0, 5.0};
  double mean = calculate_mean(numbers);
  fmt::print("Mean of {{1, 2, 3, 4, 5}}: {:.2f}\n", mean);

  return 0;
}
