import std/array/bound-checks

-- Functional 
all(array, pred) ->
        empty(array) ? true
                     : pred(array[0]) & all(array[..-1])

any(array, pred) ->
        empty(array) ? false
                     : pred(array[0]) | any(array[..-1])

none(array, pred) -> !any(array, pred)

filter(array, pred)
:       result <- pred(array[0]) ? [array[0]] : []
->
        empty(array) ? []
                     : result ~ filter(array[..-1], pred)

map(array, func) ->
        empty(array) ? []
                     : [func(array[0])] ~ map(array[..-1], func)