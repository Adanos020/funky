-- Bound checks 
empty(list) -> list = []

length(list) -> empty(list) ? 0 : 1 + length(list[1..])

in bounds(list, index) -> index = 0 .. length(list)