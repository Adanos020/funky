-- Bound checks
empty (array) -> array = []

length (array) -> empty (array) ? 0 : 1 + length (array[1...])

in bounds (array, index) -> index = 0 .. length (array)