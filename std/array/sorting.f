import std/array/functional

== Sorts given `array` in the ascending order.
==
== Returns: Array
==     Array of sorted elements from `array`.
sort (array) {
    end << array = [],
    less << end ? [] : filter (array, x -> x <  array[0]),
    more << end ? [] : filter (array, x -> x >= array[0])
} ->
    end ? [] : sort (less) ~ array[0] ~ sort (more)