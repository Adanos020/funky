import std/array/bound-checks
import std/array/functional

== Makes a new array with length equal to the length of given `array`, filled
== with given `value`.
==
== Returns: Array
fill (array, value) ->
    empty (array) ? [] : [value] ~ fill (array[1...], value)

== Makes a new array from given `array` without its element at given `index`.
==
== Return: Array
remove (array, index) ->
    in bounds (array, index) ? array[..index] ~ array[index + 1...] : array