-- Arithmetic
gcd(a, b) -> a > b ? gcd(a % b, b)
           : a < b ? gcd(a, b % a)
           : a