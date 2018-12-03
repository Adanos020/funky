import std/array/bound-checks
import std/array/functional

== Makes a new array with length equal to the length of given `array`, filled
== with given `value`.
==
== 
fill (array, value) ->
    empty (array) ? [] : [value] ~ fill (array[1...], value)

remove (array, index) ->
    in bounds (array, index) ? array[..index] ~ array[index + 1...] : array
