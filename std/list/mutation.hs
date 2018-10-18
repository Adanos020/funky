import std/list/bound-checks
import std/algorithm/functional

-- Mutation 
fill(list, value) ->
        empty(list) ? [] : [value] ~ fill(list[1..], value)

remove(list, index) ->
        in bounds(list, index) ? list[..index] ~ list[index + 1..] : list