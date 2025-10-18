#pragma once

#include <vector>
#include <numeric>
#include <cmath>

namespace myproject {

/**
 * @brief Element-wise addition of two vectors
 */
std::vector<double> add_vectors(const std::vector<double>& a, const std::vector<double>& b);

/**
 * @brief Compute dot product of two vectors
 */
double dot_product(const std::vector<double>& a, const std::vector<double>& b);

/**
 * @brief Compute Euclidean norm of a vector
 */
double vector_norm(const std::vector<double>& v);

/**
 * @brief Simple matrix class for demo
 */
class Matrix {
public:
    Matrix(size_t rows, size_t cols);
    Matrix(const std::vector<std::vector<double>>& data);
    
    size_t rows() const { return rows_; }
    size_t cols() const { return cols_; }
    
    double& at(size_t i, size_t j);
    double at(size_t i, size_t j) const;
    
    Matrix operator+(const Matrix& other) const;
    Matrix operator*(double scalar) const;
    
    std::vector<double> to_vector() const;
    
private:
    size_t rows_, cols_;
    std::vector<double> data_;
};

} // namespace myproject