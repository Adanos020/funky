-- Linear interpolation 
lerp num (val 1, val 2, alpha) ->
        (1 - alpha) * val 1 + alpha * val 2

lerp vec (vec 1, vec 2, alpha) -> {
        x <- lerp (vec 1 :: x, vec 2 :: x, alpha),
        y <- lerp (vec 1 :: y, vec 2 :: y, alpha)
}