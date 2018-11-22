-- Choice
min (a, b) -> a < b ? a : b
max (a, b) -> a > b ? a : b
clamp (lo, hi, value) -> min (max (lo, value), hi)