import std/array/bound-checks

-- Series
sum (array) -> empty (array) ? 0 : array[0] + sum (array[1...])