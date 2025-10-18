"""Tests for Python bindings and high-level interface."""

import pytest
import numpy as np
from myproject import (
    greet,
    add_numbers,
    add_vectors,
    dot_product,
    vector_norm,
    Matrix,
    normalize_vector,
    matrix_from_numpy,
    compute_distance,
    __version__,
)


def test_version():
    """Test version is defined."""
    assert __version__ == "0.1.0"


class TestCoreBindings:
    """Test C++ core function bindings."""
    
    def test_greet(self):
        """Test greet function."""
        assert greet("World") == "Hello, World!"
        with pytest.raises(Exception):
            greet("")
    
    def test_add_numbers(self):
        """Test add_numbers function."""
        assert add_numbers(2.5, 3.5) == 6.0
        assert add_numbers(-1, 1) == 0


class TestVectorOperations:
    """Test vector operation bindings."""
    
    def test_add_vectors(self):
        """Test vector addition."""
        a = np.array([1, 2, 3])
        b = np.array([4, 5, 6])
        result = add_vectors(a, b)
        np.testing.assert_array_equal(result, [5, 7, 9])
    
    def test_add_vectors_mismatch(self):
        """Test vector addition with mismatched sizes."""
        a = np.array([1, 2])
        b = np.array([3, 4, 5])
        with pytest.raises(Exception):
            add_vectors(a, b)
    
    def test_dot_product(self):
        """Test dot product."""
        a = np.array([1, 2, 3])
        b = np.array([4, 5, 6])
        assert dot_product(a, b) == 32  # 1*4 + 2*5 + 3*6
    
    def test_vector_norm(self):
        """Test vector norm."""
        v = np.array([3, 4])  # 3-4-5 triangle
        assert vector_norm(v) == 5.0


class TestMatrix:
    """Test Matrix class bindings."""
    
    def test_construction(self):
        """Test matrix construction."""
        m1 = Matrix(2, 3)
        assert m1.rows == 2
        assert m1.cols == 3
        
        m2 = Matrix([[1, 2], [3, 4]])
        assert m2.rows == 2
        assert m2.cols == 2
    
    def test_indexing(self):
        """Test matrix indexing."""
        m = Matrix([[1, 2], [3, 4]])
        assert m[0, 0] == 1
        assert m[0, 1] == 2
        assert m[1, 0] == 3
        assert m[1, 1] == 4
        
        m[0, 0] = 10
        assert m[0, 0] == 10
    
    def test_addition(self):
        """Test matrix addition."""
        m1 = Matrix([[1, 2], [3, 4]])
        m2 = Matrix([[5, 6], [7, 8]])
        m3 = m1 + m2
        
        assert m3[0, 0] == 6
        assert m3[0, 1] == 8
        assert m3[1, 0] == 10
        assert m3[1, 1] == 12
    
    def test_scalar_multiplication(self):
        """Test matrix scalar multiplication."""
        m = Matrix([[1, 2], [3, 4]])
        m2 = m * 2
        
        assert m2[0, 0] == 2
        assert m2[0, 1] == 4
        assert m2[1, 0] == 6
        assert m2[1, 1] == 8
    
    def test_to_numpy(self):
        """Test conversion to numpy array."""
        m = Matrix([[1, 2], [3, 4]])
        arr = m.to_numpy()
        
        assert isinstance(arr, np.ndarray)
        assert arr.shape == (2, 2)
        np.testing.assert_array_equal(arr, [[1, 2], [3, 4]])


class TestHighLevel:
    """Test high-level Python interface."""
    
    def test_normalize_vector(self):
        """Test vector normalization."""
        v = [3, 4]  # norm = 5
        normalized = normalize_vector(v)
        np.testing.assert_array_almost_equal(normalized, [0.6, 0.8])
        assert abs(vector_norm(normalized) - 1.0) < 1e-10
    
    def test_normalize_zero_vector(self):
        """Test normalizing zero vector."""
        v = [0, 0, 0]
        normalized = normalize_vector(v)
        np.testing.assert_array_equal(normalized, v)
    
    def test_matrix_from_numpy(self):
        """Test creating Matrix from numpy array."""
        arr = np.array([[1, 2], [3, 4]])
        m = matrix_from_numpy(arr)
        
        assert m.rows == 2
        assert m.cols == 2
        assert m[0, 0] == 1
        assert m[1, 1] == 4
    
    def test_compute_distance(self):
        """Test distance computation."""
        v1 = [1, 2, 3]
        v2 = [4, 6, 3]
        dist = compute_distance(v1, v2)
        assert dist == 5.0  # sqrt((4-1)^2 + (6-2)^2 + (3-3)^2)


@pytest.mark.parametrize("a,b,expected", [
    ([1, 1], [1, 1], [2, 2]),
    ([0, 0], [5, 5], [5, 5]),
    ([-1, -2], [1, 2], [0, 0]),
])
def test_add_vectors_parametrized(a, b, expected):
    """Parametrized test for vector addition."""
    result = add_vectors(np.array(a), np.array(b))
    np.testing.assert_array_equal(result, expected)