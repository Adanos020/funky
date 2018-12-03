import std/array/bound-checks

-- Searching 
can find (array, value) ->
    can find if (array, x -> x = value)

can find if (array, predicate) ->
    array != [] & (predicate (array[0]) | can find if (array[1...], predicate))

find (array, value) ->
    find if (array, v -> v = value)

find if (array, predicate) ->
    array = [] | predicate (array[0]) ? array : find if (array[1...], predicate)

find index (array, value) ->
    find index if (array, x -> x = value)

find index if (array, predicate) {
    len <- length (array),
    index <- len - length (find if (array, predicate))
} ->
    index = len ? -1 : index

count (array, value) ->
    count if (array, x -> x = value)

count if (array, predicate) {
    end <- array = [],
    add <- !end & predicate (array[0]) ? 1 : 0
} ->
    add + (end ? 0 : count if (array[1...], predicate))