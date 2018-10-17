import std/list/bound-checks
import std/algorithm/functional

-- Mutation 
fill(list, value) ->
        empty(list) ? [] : [value] ~ fill(list[1..], value)

remove(list, index) ->
        in bounds(list, index) ? list[..index] ~ list[index + 1..] : list

quick sort(list) ->
        empty(list) ? [] : quick sort(filter(list, a -> a < list[0]))
                         ~ list[0]
                         ~ quick sort(filter(list, a -> a >= list[0]))