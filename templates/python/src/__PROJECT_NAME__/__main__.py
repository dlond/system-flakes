"""CLI entry point for __PROJECT_NAME__."""

import sys

from __PROJECT_NAME__.core import greet


def main() -> int:
    """Main entry point."""
    if len(sys.argv) > 1:
        name = sys.argv[1]
    else:
        name = "World"

    print(greet(name))
    return 0


if __name__ == "__main__":
    sys.exit(main())
