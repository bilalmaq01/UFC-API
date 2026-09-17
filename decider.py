"""
I say higher or lower when i want to make an important decision in the decision making of this project but cant decide
"""

import random


def roll() -> int:

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
