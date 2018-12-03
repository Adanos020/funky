== Checks if given `array` is empty.
==
== Returns: Boolean
==     True if `array` is empty, false otherwise.
empty (array) -> array = []

== Counts the number of elements in the array.
==
== Returns: Number
length (array) -> empty (array) ? 0 : 1 + length (array[1...])

== Checks if given `index` is within the bounds of given `array`.
==
== Returns: Boolean
==     True if the index is in range (-len + 1; len), false otherwise.
in bounds (array, index) {
    len << length (array)
} ->
    index = -len + 2 .. len