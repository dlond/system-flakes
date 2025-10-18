#include "myproject/calculator.h"
#include <stdexcept>

namespace myproject {

Calculator::Calculator(double initial_value) : value_(initial_value) {}

Calculator& Calculator::add(double x) {
    value_ += x;
    return *this;
}

Calculator& Calculator::multiply(double x) {
    value_ *= x;
    return *this;
}

Calculator& Calculator::divide(double x) {
    if (x == 0) {
        throw std::invalid_argument("Cannot divide by zero");
    }
    value_ /= x;
    return *this;
}

Calculator& Calculator::reset() {
    value_ = 0;
    return *this;
}

double Calculator::result() const {
    return value_;
}

} // namespace myproject