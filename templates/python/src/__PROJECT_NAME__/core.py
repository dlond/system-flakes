"""Core functionality for the project."""


def greet(name: str) -> str:
    """Return a greeting message.
    
    Args:
        name: The name to greet.
        
    Returns:
        A greeting string.
    """
    if not name:
        raise ValueError("Name cannot be empty")
    return f"Hello, {name}!"


def add_numbers(a: float, b: float) -> float:
    """Add two numbers together.
    
    Args:
        a: First number.
        b: Second number.
        
    Returns:
        The sum of a and b.
    """
    return a + b


class Calculator:
    """A simple calculator class."""
    
    def __init__(self, initial_value: float = 0):
        """Initialize calculator with a value."""
        self.value = initial_value
    
    def add(self, x: float) -> "Calculator":
        """Add to the current value."""
        self.value += x
        return self
    
    def multiply(self, x: float) -> "Calculator":
        """Multiply the current value."""
        self.value *= x
        return self
    
    def reset(self) -> "Calculator":
        """Reset to zero."""
        self.value = 0
        return self
    
    def result(self) -> float:
        """Get the current value."""
        return self.value