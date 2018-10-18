import std/list/bound-checks

-- Series
sum(list) -> empty(list) ? 0 : list[0] + sum(list[1..])