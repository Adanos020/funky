import std/array/bound-checks
import std/array/functional

-- Sorting
sort (array):
        less <- filter (array, x -> x <  array[0]),
        more <- filter (array, x -> x >= array[0])
->
        empty (array) ? []
                      : sort (less) ~ array[0] ~ sort (more)