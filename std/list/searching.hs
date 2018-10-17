import std/list/bound-checks

-- Searching 
can find(list, value) ->
        !empty(list) & (list[0] = value | can find(list[1..], value))

find(list, value) ->
        find if(list, v -> v = value)

find if(list, pred) ->
        empty(list) | pred(list[0]) ? list : find if(list[1..], pred)

find index(list, pred) ->
        find index if(list, v -> pred(v))

find index if(list, pred) ->
        length(list) - length(find if(list, pred))

count(list, value) ->
        count if(list, v -> v = value)

count if(list, pred) ->
        empty(list) | !pred(list[0]) ? 0 : 1 + count if(list[1..], pred)