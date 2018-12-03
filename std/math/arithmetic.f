== Computes the greatest common divider of given numbers `a` and `b`.
==
== Returns: Number
gcd (a, b) -> a > b ? gcd (a - b, b)
            : a < b ? gcd (a, b - a)
            : a