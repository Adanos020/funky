import std/array/bound-checks

-- Searching 
can find (array, value) ->
    can find if (array, x -> x = value)

can find if (array, pred) ->
    !empty (array) & (pred (array[0]) | can find (array[1...], value))

find (array, value) ->
    find if (array, v -> v = value)

find if (array, pred) ->
    empty (array) | pred (array[0]) ? array : find if (array[1...], pred)

find index (array, pred) ->
    find index if (array, v -> pred (v))

find index if (array, pred) ->
    length (array) - length (find if (array, pred))

count (array, value) ->
    count if (array, v -> v = value)

count if (array, pred) ->
    !empty (array) & pred (array[0]) ? 1 + count if (array[1...], pred) : 0