#include "myproject/math_ops.h"
#include <stdexcept>
#include <algorithm>

namespace myproject {

std::vector<double> add_vectors(const std::vector<double>& a, const std::vector<double>& b) {
    if (a.size() != b.size()) {
        throw std::invalid_argument("Vectors must have the same size");
    }
    
    std::vector<double> result(a.size());
    for (size_t i = 0; i < a.size(); ++i) {
        result[i] = a[i] + b[i];
    }
    return result;
}

double dot_product(const std::vector<double>& a, const std::vector<double>& b) {
    if (a.size() != b.size()) {
        throw std::invalid_argument("Vectors must have the same size");
    }
    
    double result = 0.0;
    for (size_t i = 0; i < a.size(); ++i) {
        result += a[i] * b[i];
    }
    return result;
}

double vector_norm(const std::vector<double>& v) {
    double sum_squares = 0.0;
    for (double val : v) {
        sum_squares += val * val;
    }
    return std::sqrt(sum_squares);
}

// Matrix implementation
Matrix::Matrix(size_t rows, size_t cols) 
    : rows_(rows), cols_(cols), data_(rows * cols, 0.0) {}

Matrix::Matrix(const std::vector<std::vector<double>>& data) {
    if (data.empty()) {
        throw std::invalid_argument("Matrix cannot be empty");
    }
    
    rows_ = data.size();
    cols_ = data[0].size();
    data_.reserve(rows_ * cols_);
    
    for (const auto& row : data) {
        if (row.size() != cols_) {
            throw std::invalid_argument("All rows must have the same size");
        }
        data_.insert(data_.end(), row.begin(), row.end());
    }
}

double& Matrix::at(size_t i, size_t j) {
    if (i >= rows_ || j >= cols_) {
        throw std::out_of_range("Matrix index out of range");
    }
    return data_[i * cols_ + j];
}

double Matrix::at(size_t i, size_t j) const {
    if (i >= rows_ || j >= cols_) {
        throw std::out_of_range("Matrix index out of range");
    }
    return data_[i * cols_ + j];
}

Matrix Matrix::operator+(const Matrix& other) const {
    if (rows_ != other.rows_ || cols_ != other.cols_) {
        throw std::invalid_argument("Matrices must have the same dimensions");
    }
    
    Matrix result(rows_, cols_);
    for (size_t i = 0; i < data_.size(); ++i) {
        result.data_[i] = data_[i] + other.data_[i];
    }
    return result;
}

Matrix Matrix::operator*(double scalar) const {
    Matrix result(rows_, cols_);
    for (size_t i = 0; i < data_.size(); ++i) {
        result.data_[i] = data_[i] * scalar;
    }
    return result;
}

std::vector<double> Matrix::to_vector() const {
    return data_;
}

} // namespace myproject