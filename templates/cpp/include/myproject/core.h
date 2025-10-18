#pragma once

#include <string>
#include <vector>

namespace myproject {

/**
 * @brief Greet a person by name
 * @param name The name to greet
 * @return Greeting message
 */
std::string greet(const std::string& name);

/**
 * @brief Add two numbers
 * @param a First number
 * @param b Second number
 * @return Sum of a and b
 */
double add_numbers(double a, double b);

/**
 * @brief Calculate the mean of a vector
 * @param values Vector of values
 * @return Mean value, or 0 if empty
 */
double calculate_mean(const std::vector<double>& values);

} // namespace myproject