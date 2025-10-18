"""Tests for core module."""

import pytest
from myproject import greet, add_numbers, __version__
from myproject.core import Calculator


def test_version():
    """Test that version is defined."""
    assert __version__ == "0.1.0"


class TestGreet:
    """Tests for greet function."""
    
    def test_greet_basic(self):
        """Test basic greeting."""
        assert greet("World") == "Hello, World!"
    
    def test_greet_with_name(self):
        """Test greeting with different names."""
        assert greet("Alice") == "Hello, Alice!"
        assert greet("Bob") == "Hello, Bob!"
    
    def test_greet_empty_raises(self):
        """Test that empty name raises ValueError."""
        with pytest.raises(ValueError, match="Name cannot be empty"):
            greet("")


class TestAddNumbers:
    """Tests for add_numbers function."""
    
    def test_add_integers(self):
        """Test adding integers."""
        assert add_numbers(2, 3) == 5
    
    def test_add_floats(self):
        """Test adding floats."""
        assert add_numbers(2.5, 3.5) == 6.0
    
    def test_add_negative(self):
        """Test adding negative numbers."""
        assert add_numbers(-1, 1) == 0
        assert add_numbers(-5, -3) == -8


class TestCalculator:
    """Tests for Calculator class."""
    
    def test_init_default(self):
        """Test default initialization."""
        calc = Calculator()
        assert calc.result() == 0
    
    def test_init_with_value(self):
        """Test initialization with value."""
        calc = Calculator(10)
        assert calc.result() == 10
    
    def test_add(self):
        """Test addition."""
        calc = Calculator(5)
        calc.add(3)
        assert calc.result() == 8
    
    def test_multiply(self):
        """Test multiplication."""
        calc = Calculator(4)
        calc.multiply(3)
        assert calc.result() == 12
    
    def test_chaining(self):
        """Test method chaining."""
        calc = Calculator(2)
        result = calc.add(3).multiply(4).add(1).result()
        assert result == 21  # (2+3)*4+1 = 21
    
    def test_reset(self):
        """Test reset functionality."""
        calc = Calculator(100)
        calc.reset()
        assert calc.result() == 0


@pytest.mark.parametrize("a,b,expected", [
    (1, 1, 2),
    (0, 0, 0),
    (100, 200, 300),
    (-50, 50, 0),
])
def test_add_parametrized(a, b, expected):
    """Parametrized test for add_numbers."""
    assert add_numbers(a, b) == expected