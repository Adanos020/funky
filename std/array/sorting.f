import std/array/bound-checks
import std/array/functional

-- Sorting
sort (array) {
    end <- empty (array),
    less <- end ? [] : filter (array, x -> x <  array[0]),
    more <- end ? [] : filter (array, x -> x >= array[0])
} ->
    end ? [] : sort (less) ~ array[0] ~ sort (more)