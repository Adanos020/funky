import std/array/bound-checks

== Checks if given `value` exists in given `array`.
==
== Returns: Boolean
==     True if `value` is found, false otherwise.
can find (array, value) ->
    can find if (array, x -> x = value)

== Checks if at least one value in given `array` meets the condition specified
== in given `predicate`.
==
== Returns: Boolean
==     True if such value is found, false otherwise.
can find if (array, predicate) ->
    array != [] & (predicate (array[0]) | can find if (array[1...], predicate))

== Linearly searches given `array` for the first occurrence of given `value`.
==
== Returns: Array
==     Array starting at the position of the sought `value`, or empty array if
==     it's not found.
find (array, value) ->
    find if (array, v -> v = value)

== Linearly searches given `array` for the first value meeting the condition
== specified in given `predicate`.
==
== Returns: Array
==     Array starting at the position of the sought value, or empty array if
==     it's not found.
find if (array, predicate) ->
    array = [] | predicate (array[0]) ? array : find if (array[1...], predicate)

== Linearly searches given `array` for the first occurrence of given `value`.
==
== Returns: Number
==     Index of the sought `value`, or -1 if it's not found.
find index (array, value) ->
    find index if (array, x -> x = value)

== Linearly searches given `array` for the first value meeting the condition
== specified in given `predicate`.
==
== Returns: Number
==     Index of the sought `value`, or -1 if it's not found.
find index if (array, predicate) {
    len << length (array),
    index << len - length (find if (array, predicate))
} ->
    index = len ? -1 : index

== Counts all occurrences of given `value` in given `array`.
==
== Returns: Number
==     Number of occurrences of `value`.
count (array, value) ->
    count if (array, x -> x = value)

== Counts all values in given `array` that meet the condition specified in given
== `predicate`.
==
== Returns: Number
==     Number of such values in `array`.
count if (array, predicate) {
    end << array = [],
    add << !end & predicate (array[0]) ? 1 : 0
} ->
    add + (end ? 0 : count if (array[1...], predicate))