import std/array/bound-checks

== Adds all values in given `array` together.
==
== Returns: Number
==     Sum of all numbers in the `array`.
sum (array) -> array = [] ? 0 : array[0] + sum (array[1...])