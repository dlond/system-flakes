#include "myproject/core.h"
#include <fmt/format.h>
#include <stdexcept>

namespace myproject {

std::string greet(const std::string& name) {
    if (name.empty()) {
        throw std::invalid_argument("Name cannot be empty");
    }
    return fmt::format("Hello, {}!", name);
}

double add_numbers(double a, double b) {
    return a + b;
}

} // namespace myproject