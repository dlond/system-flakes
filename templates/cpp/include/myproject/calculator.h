#pragma once

namespace myproject {

/**
 * @brief A simple calculator class with fluent interface
 */
class Calculator {
public:
    /**
     * @brief Construct calculator with initial value
     * @param initial_value Starting value (default: 0)
     */
    explicit Calculator(double initial_value = 0);

    /**
     * @brief Add to current value
     * @param x Value to add
     * @return Reference to this for chaining
     */
    Calculator& add(double x);

    /**
     * @brief Multiply current value
     * @param x Value to multiply by
     * @return Reference to this for chaining
     */
    Calculator& multiply(double x);

    /**
     * @brief Divide current value
     * @param x Value to divide by
     * @return Reference to this for chaining
     * @throws std::invalid_argument if x is 0
     */
    Calculator& divide(double x);

    /**
     * @brief Reset to zero
     * @return Reference to this for chaining
     */
    Calculator& reset();

    /**
     * @brief Get current value
     * @return Current calculator value
     */
    double result() const;

private:
    double value_;
};

} // namespace myproject