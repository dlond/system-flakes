"""MyProject - Python package with C++ extensions."""

__version__ = "0.1.0"

# Import C++ extension
from ._myproject_ext import (
    greet,
    add_numbers,
    add_vectors,
    dot_product,
    vector_norm,
    Matrix,
    __version__ as _ext_version,
)

# Import Python helpers
from .high_level import (
    normalize_vector,
    matrix_from_numpy,
    compute_distance,
)

__all__ = [
    # From C++ extension
    "greet",
    "add_numbers",
    "add_vectors", 
    "dot_product",
    "vector_norm",
    "Matrix",
    # From Python
    "normalize_vector",
    "matrix_from_numpy",
    "compute_distance",
    "__version__",
]

# Verify extension version matches
assert _ext_version == __version__, f"Extension version {_ext_version} != {__version__}"