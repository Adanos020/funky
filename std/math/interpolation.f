== Linearly interpolates between two numbers.
==
== Returns: Number
lerp num (val 1, val 2, alpha) ->
    (1 - alpha) * val 1 + alpha * val 2

== Linearly interpolates between two vectors.
==
== Returns: Number
lerp vec (vec 1, vec 2, alpha) -> {
    x <- lerp (vec 1 :: x, vec 2 :: x, alpha)
    y <- lerp (vec 1 :: y, vec 2 :: y, alpha)
}