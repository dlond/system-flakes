#include "myproject/core.h"
#include "myproject/math_ops.h"
#include <fmt/core.h>
#include <fmt/ranges.h>
#include <iostream>

int main() {
    using namespace myproject;
    
    // Test core functions
    fmt::print("{}\n", greet("World"));
    fmt::print("2 + 3 = {}\n", add_numbers(2, 3));
    
    // Test vector operations
    std::vector<double> v1 = {1, 2, 3};
    std::vector<double> v2 = {4, 5, 6};
    
    auto sum = add_vectors(v1, v2);
    fmt::print("v1 + v2 = {}\n", sum);
    
    double dot = dot_product(v1, v2);
    fmt::print("v1 · v2 = {}\n", dot);
    
    double norm = vector_norm(v1);
    fmt::print("||v1|| = {:.3f}\n", norm);
    
    // Test matrix operations
    Matrix m1({{1, 2}, {3, 4}});
    Matrix m2({{5, 6}, {7, 8}});
    
    Matrix m3 = m1 + m2;
    fmt::print("Matrix sum:\n");
    for (size_t i = 0; i < m3.rows(); ++i) {
        for (size_t j = 0; j < m3.cols(); ++j) {
            fmt::print("{:4.0f} ", m3.at(i, j));
        }
        fmt::print("\n");
    }
    
    return 0;
}