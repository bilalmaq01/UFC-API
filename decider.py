"""Random decision oracle.

Rolls a number from 1 to 100, using 50 as the midpoint, and reports which
side it landed on. We map the two choices to HIGHER / LOWER beforehand, roll,
and let the number decide.

  - roll >  50  -> HIGHER
  - roll <  50  -> LOWER
  - roll == 50  -> dead center, re-roll

Usage:
    python decider.py
"""

import random


def roll() -> int:
    """Return a random integer from 1 to 100 (both ends included)."""
    return random.randint(1, 100)


def verdict(n: int) -> str:
    if n > 50:
        return "HIGHER"
    if n < 50:
        return "LOWER"
    return "MIDDLE — exactly 50, re-roll"


if __name__ == "__main__":
    n = roll()
    print(f"rolled {n}  ->  {verdict(n)}")
