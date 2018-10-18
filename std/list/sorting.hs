import std/list/bound-checks
import std/list/functional

-- Sorting
partition sort(list):
        less <- filter(list, x -> x <  list[0]),
        more <- filter(list, x -> x >= list[0])
->
        empty(list) ? []
                    : partition sort(less) ~ list[0] ~ partition sort(more)