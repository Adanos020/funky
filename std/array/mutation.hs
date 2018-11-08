import std/array/bound-checks
import std/algorithm/functional

-- Mutation
fill(array, value) ->
        empty(array) ? [] : [value] ~ fill(array[..-1], value)

remove(array, index) ->
        in bounds(array, index) ? array[..index] ~ array[index + 1..] : array