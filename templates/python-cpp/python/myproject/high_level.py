"""High-level Python interface for myproject."""

import numpy as np
from typing import Union, List
from . import vector_norm, add_vectors, Matrix


def normalize_vector(v: Union[np.ndarray, List[float]]) -> np.ndarray:
    """Normalize a vector to unit length.
    
    Args:
        v: Input vector as numpy array or list
        
    Returns:
        Normalized vector as numpy array
    """
    v = np.asarray(v)
    norm = vector_norm(v)
    if norm == 0:
        return v
    return v / norm


def matrix_from_numpy(arr: np.ndarray) -> Matrix:
    """Create a Matrix object from a numpy array.
    
    Args:
        arr: 2D numpy array
        
    Returns:
        Matrix object
    """
    if arr.ndim != 2:
        raise ValueError("Input must be a 2D array")
    return Matrix(arr.tolist())


def compute_distance(v1: Union[np.ndarray, List[float]], 
                    v2: Union[np.ndarray, List[float]]) -> float:
    """Compute Euclidean distance between two vectors.
    
    Args:
        v1: First vector
        v2: Second vector
        
    Returns:
        Euclidean distance
    """
    v1 = np.asarray(v1)
    v2 = np.asarray(v2)
    diff = v1 - v2
    return vector_norm(diff)