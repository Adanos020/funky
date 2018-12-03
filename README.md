# Funky
Interpreter for my simple functional language, created for educational purposes.



# How to build and use
Use [DUB](https://code.dlang.org/getting_started) for building.

To use the interpreter simply use command `./funky` and pass paths to the source files that you want to execute as arguments.
```bash
$ ./funky my-program.f
```

Not giving any arguments or passing a file where the `exit()` or `quit()` function isn't called will open the interpreter console. There, you can execute any Funky code in real time. To exit the interpreter simply press Ctrl+C or call the `exit()` or `quit()` function.



# Syntax
While designing the syntax I was inspired mainly by syntaxes of Haskell, C++, D, and JavaScript, but also introduced some of my new ideas. I tried my best to make it as simple as possible, with minimal use of keywords. For instance, a simple Hello World program would look like this:
```
"Hello, world!"
```

There's no special function for printing things in the console. To print anything – just input it and it's done.


## Identifiers
All variables, functions, and classes are referred to by a name you give them. Names must begin with a letter, and after that can consist of:
- letters (both lower- and upper-case)
- digits
- the apostrophe: `'`
- all printable unicode characters
- spaces and tabs

Yes, correct! Spaces can be used in all identifiers so there's no more need to argue whether to use camelCase, snake_case, or other weird naming convention. All of the following combinations are permitted and treated as single names.
```
variable
another variable
that's 2 ez 4 me
tab	is	good	too
```

Moreover, the number of spaces between words is ignored, meaning that both of the following variants are treated as the same name. Might be useful for alignment of similar names.
```
this is a sample name
this     is     a  sample        name
```

The main naming convention is:
- words variable and function names are usually starting with a lower-case letter, except for proper names which are capitalised: `a variable`, `height of the Eiffel tower`
- words in constant names are all upper-case: `PI`, `PLANCK CONSTANT`


## Modules
Modules are simply source files (which must have the ".f" extension) which can be imported from a path relative to the interpreter executable. Whole packages (folders with source files) can also be imported.
```
import std/math/constants == imports the module "std/math/constants.f"
import std/math           == imports all modules in "std/math/"
```


## Comments
Funky supports only single line comments.
```
== Everyone ignores me
```


## Variables
In order to create or assign to a variable, simply input its name, a leftward arrow `<-`, and the value.
```
some number <- 10
```

You can also create constants, you only need to input a double leftward arrow `<<` instead of the single one. **Note:** you cannot reassign to a constant!
```
GRAVITATIONAL CONSTANT << 6.67408e-10
GRAVITATIONAL CONSTANT << 7 == error!
```

What you can do, though, is to change a variable into a constant.
```
thank the bus driver <- false
thank the bus driver << true == ok and very wholesome
```

Funky is dynamically typed, meaning that a variable can change its value type on the fly.
```
bipolar <- 2
bipolar <- "who am I"
```

## Arithmetics
To make a number literal, simply input digits. You can input a decimal point if you need too. In longer numbers you can input spaces for readability (as in identifiers, number of spaces is ignored).
```
dozen <- 12
PI << 3.14 159 265 359
```

Scientific notation is supported too.
```
kilo <- 1e3
micro <- 1e-6
approximate world population <- 7.7e+9 == the `+` doesn't change anything, it's just there
```

There are also special literals for infinity `inf` and not a number `nan`.

Arithmetic operations include addition (`a + b`), subtraction (`a - b`), multiplication (`a * b`), division (`a / b`), modulo (remainder of division) (`a % b`), powers (`a ^ b`), and negation (`-a`).

All these operations have their fixed precedence, due to which the following expression:
```
4 + -3 ^ 2 * (6 - 1) / 5
```

will be evaluated like this:
```
4 + ((-3) ^ 2) * ((6 - 1) / 5)
```

## Strings

A string literal is composed of any string of characters surrounded by two quotation marks, `"like this"`.

If you want to input a quotation mark inside a string, you need to input a backslash before it: `"as Einstein said someday: \"no\"."`.

Because backslash makes its following character escaped, to input an actual backslash in a string you got to input two of them, right next to each other: `"this is a backslash: \\"`.

To join two strings together simply input the `~` character between both of them.
```
greeting  <- "Hello"
addressee <- "world"
message   <- greeting ~ ", " ~ addressee ~ "!"
```

You can also join other types of values, provided a string is the first in the chain. Joined values will automatically be converted into a string.
```
"Stay hydrated, " ~ 820 ~ " pal" == prints "Stay hydrated, 820 pal"
```

(String slicing and indexing is still work in progress.)


## Arrays
To create an array of values simply input square brackets and list all the values, separated by commas. Values of different types can be stored in one array.
```
some random array <- [21, 37, "those are totally random numbers", true]
```

You can easily access the elements of an array by inserting square brackets after it, and an index value inside, where 0 stands for the first element. Negative indices mean to start indexing from the last element (for which stands -1).
```
prime numbers <- [2, 3, 5, 7, 11, 13]
prime numbers[0]  == 2
prime numbers[2]  == 5
prime numbers[-1] == 13
```

**Note:** any index outside the array bounds is an error.

Each element can be assigned to as follows.
```
array <- [1, 9, 8, 4]
array[-2] <- 9
array == prints [1, 9, 9, 4]
```

### Array slicing
You can join arrays exactly like strings, with a small exception. Joining different values will simply add them to the preceding array.
```
numbers again <- [1, 1, 2, 3, 5, 8, 13]
and     again <- numbers again ~ [21, 34, 55] == [1, 1, 2, 3, 5, 8, 13, 21, 34, 55]
and yet again <- and again ~ 89 ~ 154         == [1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 154]
== oh what a nice square shape I made here
```

You can also slice arrays, i.e. take their smaller parts and treat them as new arrays... kinda. They are in fact just new references to a part of the original array, so changing a value in a slice changes the value in the array from which the slice was taken.

To get a slice, use a similar notation as in indexing, except instead of indices use numerical ranges. There are two types of numerical ranges in Funky: upper-inclusive and upper-exclusive, meaning that the upper bound can be either included in or excluded out of the range. The notation for both types of ranges looks like this:
```
lower ... upper == upper-inclusive, corresponds to mathematical [lower, upper]
lower ..  upper == upper-exclusive, corresponds to mathematical [lower, upper)
```

**Note:** the lower bound in array slicing must be actually lower than the upper, otherwise it's an error. In other contexts it may vary.

So given an array named `a` with values `[1, 2, 3, 4, 5]`, to retrieve `[2, 3, 4]` from it we can use either:
```
a[1 ... 3]
== or
a[1 .. 4]
```

**Note:** concatenating two slices allocates a new array, which is no more sharing the elements with the original arrays.

If you skip one of the range bounds, one of the following two variants will be assumed:
- If the lower bound is skipped, the range starts at 0
- If the upper bound is skipped, the range ends at the last element's index
```
a <- [1, 2, 3, 4, 5]
a[..3]  == [1, 2, 3]
a[...3] == [1, 2, 3, 4]
a[1..]  == [2, 3, 4] - the last element is not included!
a[1...] == [2, 3, 4, 5]
```

**Note:** this applies only to array slicing. In other contexts no range bound can be skipped.


## Logical expressions
The literals are nothing fancy, just `true` and `false`.

Basic operations include conjunction a.k.a. AND (`a & b`), alternative a.k.a. OR (`a | b`), exclusive alternative a.k.a. XOR (`a @ b`), and negation a.k.a. NOT (`!a`). These operations, like in arithmetics, also have fixed precedences.
```
(a & b | !c @ d) = (a & ((b | !c) @ d))
```

Each of the binary logical operators has its negated counterpart:
- NOR `a !| b = !(a | b)`
- NAND `a !& b = !(a & b)`
- XNOR `a !@ b = !(a @ b)`

**Note:** `&`, `!&`, `|`, and `!|` are resolved lazily, i.e. whether the second operand is evaluated depends on the value of the first operand. Given `false & x`, `false !& x`, `true | x`, and `true !| x`, `x` is not evaluated since the value of `x` will not change the result of the operation anyway.

### Comparisons
You can compare values to each other, and the result of each comparison is always a boolean value.
```
a =  b == a equal b
a != b == a unequal b
a >  b == a greater than b
a >= b == a greater than or equal b
a <  b == a less than b
a <= b == a less than or equal b
```

**Note:** comparisons other than for equality and inequality *must* be only between numeric types, otherwise it's an error.

**Note:** if two values are of different types, they are unequal (unlike in JavaScript where it may vary due to implicit type conversions).

Comparisons can be chained:
```
a = b = c == equivalent to: a = b & b = c
a < b < c == equivalent to: a < b & b < c
```

You can check whether a number is in a certain range with the following notation:
```
value = lower .. higher
== or, inclusively:
value = lower ... higher
```

Testing if a value fits in a given error bar is also possible using the `+-` operator:
```
length in mm = 33 +- 1 == equivalent to: length in mm = 33 - 1 ... 33 + 1
```

### Conditional evaluation
Boolean values can be used as conditions for choosing between values. The syntax for conditional expressions is exactly the same as the ternary operator in most C-style programming languages.
```
age >= 18 ? "adult" : "child"
```

For a switch-case-like code you can use nested conditional expressions.
```
fizz buzz <- n % 15 = 0 ? "FizzBuzz"
           : n % 3  = 0 ? "Fizz"
           : n % 5  = 0 ? "Buzz"
           : n
```

## Functions
They are the fundamental concept in functional programming. Functions can be created with the following syntax (obviously, without the comments below):
```
   is even (number) -> number % 2 = 0
== \_____/ \______/    \____________/
==    ↑       ↑               ↑
==  name  parameters    return value
```

Which is the shorthand notation for:
```
is even <- (number) -> number % 2 = 0
==         \________________________/
==                      ↑
==       this alone is a function literal
```

More examples:
```
say hello () -> "Hello, world!" == takes no parameters
min (a, b) -> a < b ? a : b     == more than 1 parameters must be separated by commas
```

Functions can have local variables which are resolved before the return value. Simply list them in curly brackets after the closing parenthesis `)` and before the rightward arrow `->`, each separated with a comma.
```
== possible implementation of the +- operator
fits in error bar (number, error) {
    lower bound <- number - error,
    upper bound <- number + error
} ->
    lower bound <= error <= upper bound
```

After creating a function you can call it just by inserting its name and the list of parameters inside following parentheses.
```
lesser <- min (5, 10) == 5
== recursion is also supported:
factorial (n) ->
    n < 2 ? 1
          : n * factorial (n - 1)
a lot <- factorial (9) == 362880
```

### Lambdas
Functions, as all other values, can be passed as parameters, although you don't need to assign them to any variable to do that. What you can do is make use of anonymous functions, also known as lambda expressions. In fact, the function literal shown some sections above is a lambda expression.
```
filter (array, predicate) {
    no elements <- array = [],
    appended <- !no elements & predicate (array[0]) ? [array[0]] : []
} ->
    no elements ? [] : appended ~ filter (array[1...], predicate)

even numbers <- filter ([1, 2, 3, 4, 5, 6, 7, 8],
                        x -> x % 2 = 0) == with exactly one argument no parentheses are required
even numbers == [2, 4, 6, 8]
```


## Structures
(Still work in progress, yet some functionality is currently available.)

Structs are just packs of values, created with the following notation.
```
person <- {
    name <- "Adam",
    biological sex << "male",
    age <- 20,
    greet (other person's name) -> "Hello" ~ other person's name ~ "!"
}
```

You can access fields using the `::` operator.
```
person :: greet ("Maciej") == prints: Hello, Maciej!
person :: age <- 21
person :: biological sex <- "female" == error: the field `biological sex` is constant
```

New fields in a struct can be created simply by assigning to a previously unexistent field.