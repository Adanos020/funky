import std/list/bound-checks

-- Functional 
all(list, pred) ->
        empty(list) ? true
                    : pred(list[0]) & all(list[1..])

any(list, pred) ->
        empty(list) ? false
                    : pred(list[0]) | any(list[1..])

none(list, pred) -> !any(list, pred)

filter(list, pred)
:       result <- pred(list[0]) ? [list[0]] : []
->
        empty(list) ? []
                    : result ~ filter(list[1..], pred)

map(list, func) ->
        empty(list) ? []
                    : [func(list[0])] ~ map(list[1..], func)