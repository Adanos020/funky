import std/array/bound-checks

-- Functional 
all (array, pred) ->
    empty (array) ? true
                  : pred (array[0]) & all (array[1...])

any (array, pred) ->
    empty (array) ? false
                  : pred (array[0]) | any (array[1...])

none (array, pred) -> !any (array, pred)

filter (array, predicate):
    result <- !empty (array) & predicate (array[0]) ?
              [array[0]] : []
    -> result ~ filter (array[1...], predicate)

map (array, func) ->
    empty (array) ? []
                  : [func (array[0])] ~ map (array[1...], func)

generate (n, generator) ->
    n = 0 ? [] : [generator()] ~ generate (n - 1, generator)