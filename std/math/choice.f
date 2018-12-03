== Chooses the smaller of `a` and `b`.
==
== Returns: Number
min (a, b) -> a < b ? a : b

== Chooses the greater of `a` and `b`.
==
== Returns: Number
max (a, b) -> a > b ? a : b

== Keeps given `value` in range [`lo`; `hi`].
==
== Returns: Number
==     `lo` if `value` <= `lo`, `hi` if `value` >= `hi`, `value` otherwise.
clamp (lo, hi, value) -> min (max (lo, value), hi)