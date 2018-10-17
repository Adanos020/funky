-- Operator precedence
arithmetic <- (a + b) * -c - 3 / d^2 % e
logic      <- (a | b) & !c @ d

-- Chained comparisons
relations test(a, b, c, d, e, f) -> a = b < c = d = e > f

-- Range checks
equals error(a, b, error) -> a = b +- error
within range(a, min, max) -> a = min .. max

within matrix bounds(matrix, row, col) ->
        row = 0 .. matrix::rows & col = 0 .. matrix::cols

-- Conditional
gcd(a, b) -> a > b ? gcd(a % b, b)
           : a < b ? gcd(a, b % a)
           : a

-- Concatenation
joint string <- "Hello," ~ " world!"
joint array <- [2, 1] ~ 3 ~ [3, 7]

-- Mixed expressions
raised by 2(a, b) -> a + 2 = b + 2
equal objects(b) -> {a<<b} != {a<-b}