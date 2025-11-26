#include "__PROJECT_NAME__/core.h"
#include <fmt/format.h>
#include <numeric>
#include <stdexcept>

namespace __PROJECT_NAME__ {

std::string greet(const std::string &name) {
  if (name.empty()) {
    throw std::invalid_argument("Name cannot be empty");
  }
  return fmt::format("Hello, {}!", name);
}

double add_numbers(double a, double b) { return a + b; }

double calculate_mean(const std::vector<double> &values) {
  if (values.empty()) {
    return 0.0;
  }
  double sum = std::accumulate(values.begin(), values.end(), 0.0);
  return sum / static_cast<double>(values.size());
}

} // namespace __PROJECT_NAME__
