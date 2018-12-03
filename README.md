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
<pre><code><span style="color: #66f">"Hello, world!"</span>
</code></pre>

There's no special function for printing things in the console. To print anything – just insert it and it's done.


## Identifiers
All variables, functions, and classes are referred to by a name you give them. Names must begin with a letter, and after that can consist of:
- letters (both lower- and upper-case)
- digits
- the apostrophe: `'`
- all printable unicode characters
- spaces and tabs

Yes, correct! Spaces can be used in all identifiers so there's no more need to argue whether to use camelCase, snake_case, or other weird naming convention. All of the following combinations are permitted and treated as single names.
<pre><code>variable
another variable
that's 2 ez 4 me
tab	is	good	too
</code></pre>

Moreover, the number of spaces between words is ignored, meaning that both of the following variants are treated as the same name. Might be useful for alignment of similar names.
<pre><code>this is a sample name
this     is     a  sample        name
</code></pre>

The main naming convention is:
- words variable and function names are usually starting with a lower-case letter, except for proper names which are capitalised: `a variable`, `height of the Eiffel tower`
- words in constant names are all upper-case: `PI`, `PLANCK CONSTANT`


## Modules
Modules are simply source files (which must have the ".f" extension) which can be imported from a path relative to the interpreter executable. Whole packages (folders with source files) can also be imported.
<pre><code><span style="color: orange">import</span> <span style="color: #66f">std/math/constants</span> <span style="color: gray; font-style: italic">== imports the module "std/math/constants.f"</span>
<span style="color: orange">import</span> <span style="color: #66f">std/math</span>           <span style="color: gray; font-style: italic">== imports all modules in "std/math/"</span>
</code></pre>


## Comments
Funky supports only single line comments.
<pre><code><span style="color: gray; font-style: italic">== Everyone ignores me</span>
</code></pre>


## Variables
In order to create or assign to a variable, simply insert its name, a leftward arrow `<-`, and the value.
<pre><code>some number <span style="color: red"><-</span> <span style="color: blue">10</span>
</code></pre>

You can also create constants, you only need to insert a double leftward arrow `<<` instead of the single one. **Note:** you cannot reassign to a constant!
<pre><code>GRAVITATIONAL CONSTANT <span style="color: red"><<</span> <span style="color: blue">6.67408e-10</span>
GRAVITATIONAL CONSTANT <span style="color: red"><<</span> <span style="color: blue">7</span> <span style="color: gray; font-style: italic">== error!</span>
</code></pre>

What you can do, though, is to change a variable into a constant.
<pre><code>thank the bus driver <span style="color: red"><-</span> <span style="color: orange">false</span>
thank the bus driver <span style="color: red"><<</span> <span style="color: orange">true</span> <span style="color: gray; font-style: italic">== ok and very wholesome</span>
</code></pre>

Funky is dynamically typed, meaning that a variable can change its value type on the fly.
<pre><code>bipolar <span style="color: red"><-</span> <span style="color: blue">2</span>
bipolar <span style="color: red"><-</span> <span style="color: #66f">"who am I"</span>
</code></pre>


## Arithmetics
To make a number literal, simply insert digits. You can insert a decimal point if you need too. In longer numbers you can insert spaces for readability (as in identifiers, number of spaces is ignored).
<pre><code>dozen <span style="color: red"><-</span> <span style="color: blue">12</span>
PI <span style="color: red"><<</span> <span style="color: blue">3.14 159 265 359</span>
</code></pre>

Scientific notation is supported too.
<pre><code>kilo <span style="color: red"><-</span> <span style="color: blue">1e3</span>
micro <span style="color: red"><-</span> <span style="color: blue">1e-6</span>
approximate world population <span style="color: red"><-</span> <span style="color: blue">7.7e+9</span> <span style="color: gray; font-style: italic">== the `+` doesn't change anything, it's just there</span>
</code></pre>

There are also special literals for infinity `inf` and not a number `nan`.

Arithmetic operations include addition (`a + b`), subtraction (`a - b`), multiplication (`a * b`), division (`a / b`), modulo (remainder of division) (`a % b`), powers (`a ^ b`), and negation (`-a`).

All these operations have their fixed precedence, due to which the following expression:
<pre><code><span style="color: blue">4</span> <span style="color: red">+</span> <span style="color: red">-</span><span style="color: blue">3</span> <span style="color: red">^</span> <span style="color: blue">2</span> <span style="color: red">*</span> (<span style="color: blue">6</span> <span style="color: red">-</span> <span style="color: blue">1</span>) <span style="color: red">/</span> <span style="color: blue">5</span>
</code></pre>

will be evaluated like this:
<pre><code><span style="color: blue">4</span> <span style="color: red">+</span> ((<span style="color: red">-</span><span style="color: blue">3</span>) <span style="color: red">^</span> <span style="color: blue">2</span>) <span style="color: red">*</span> ((<span style="color: blue">6</span> <span style="color: red">-</span> <span style="color: blue">1</span>) <span style="color: red">/</span> <span style="color: blue">5</span>)
</code></pre>

## Strings

A string literal is composed of any string of characters surrounded by two quotation marks, `"like this"`.

If you want to insert a quotation mark inside a string, you need to insert a backslash before it: `"as Einstein said someday: \"no\"."`.

Because backslash makes its following character escaped, to insert an actual backslash in a string you got to insert two of them, right next to each other: `"this is a backslash: \\"`.

To join two strings together simply insert the `~` character between both of them.
<pre><code>greeting  <span style="color: red"><-</span> <span style="color: #66f">"Hello"</span>
addressee <span style="color: red"><-</span> <span style="color: #66f">"world"</span>
message   <span style="color: red"><-</span> greeting <span style="color: red">~</span> <span style="color: #66f">", "</span> <span style="color: red">~</span> addressee <span style="color: red">~</span> <span style="color: #66f">"!"</span>
</code></pre>

You can also join other types of values, provided a string is the first in the chain. Joined values will automatically be converted into a string.
<pre><code><span style="color: #66f">"Stay hydrated, "</span> <span style="color: red">~</span> <span style="color: blue">820</span> <span style="color: red">~</span> <span style="color: #66f">" pal"</span> <span style="color: gray; font-style: italic">== prints "Stay hydrated, 820 pal"</span>
</code></pre>

(String slicing and indexing is still work in progress.)


## Arrays
To create an array of values simply insert square brackets and list all the values, separated by commas. Values of different types can be stored in one array.
<pre><code>some random array <span style="color: red"><-</span> [<span style="color: blue">21</span>, <span style="color: blue">37</span>, <span style="color: #66f">"those are totally random numbers"</span>, <span style="color: orange">true</span>]
</code></pre>

You can easily access the elements of an array by inserting square brackets after it, and an index value inside, where 0 stands for the first element. Negative indices mean to start indexing from the last element (for which stands -1).
<pre><code>prime numbers <span style="color: red"><-</span> [<span style="color: blue">2</span>, <span style="color: blue">3</span>, <span style="color: blue">5</span>, <span style="color: blue">7</span>, <span style="color: blue">11</span>, <span style="color: blue">13</span>]
prime numbers[<span style="color: blue">0</span>]  <span style="color: gray; font-style: italic">== 2</span>
prime numbers[<span style="color: blue">2</span>]  <span style="color: gray; font-style: italic">== 5</span>
prime numbers[-<span style="color: blue">1</span>] <span style="color: gray; font-style: italic">== 13</span>
</code></pre>

**Note:** any index outside the array bounds is an error.

Each element can be assigned to as follows.
<pre><code>array <span style="color: red"><-</span> [<span style="color: blue">1</span>, <span style="color: blue">9</span>, <span style="color: blue">8</span>, <span style="color: blue">4</span>]
array[<span style="color: red">-</span><span style="color: blue">2</span>] <span style="color: red"><-</span> <span style="color: blue">9</span>
array <span style="color: gray; font-style: italic">== prints [1, 9, 9, 4]</span>
</code></pre>

### Array slicing
You can join arrays exactly like strings, with a small exception. Joining different values will simply add them to the preceding array.
<pre><code>numbers again <span style="color: red"><-</span> [<span style="color: blue">1</span>, <span style="color: blue">1</span>, <span style="color: blue">2</span>, <span style="color: blue">3</span>, <span style="color: blue">5</span>, <span style="color: blue">8</span>, <span style="color: blue">13</span>]
and     again <span style="color: red"><-</span> numbers again <span style="color: red">~</span> [<span style="color: blue">21</span>, <span style="color: blue">34</span>, <span style="color: blue">55</span>] <span style="color: gray; font-style: italic">== [1, 1, 2, 3, 5, 8, 13, 21, 34, 55]</span>
and yet again <span style="color: red"><-</span> and again <span style="color: red">~</span> <span style="color: blue">89</span> <span style="color: red">~</span> <span style="color: blue">154</span>         <span style="color: gray; font-style: italic">== [1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 154]</span>
<span style="color: gray; font-style: italic">== oh what a nice square shape I made here</span>
</code></pre>

You can also slice arrays, i.e. take their smaller parts and treat them as new arrays... kinda. They are in fact just new references to a part of the original array, so changing a value in a slice changes the value in the array from which the slice was taken.

To get a slice, use a similar notation as in indexing, except instead of indices use numerical ranges. There are two types of numerical ranges in Funky: upper-inclusive and upper-exclusive, meaning that the upper bound can be either included in or excluded out of the range. The notation for both types of ranges looks like this:
<pre><code>lower <span style="color: red">...</span> upper <span style="color: gray; font-style: italic">== upper-inclusive, corresponds to mathematical [lower, upper]</span>
lower <span style="color: red">..</span>  upper <span style="color: gray; font-style: italic">== upper-exclusive, corresponds to mathematical [lower, upper)</span>
</code></pre>

**Note:** the lower bound in array slicing must be actually lower than the upper, otherwise it's an error. In other contexts it may vary.

So given an array named `a` with values `[1, 2, 3, 4, 5]`, to retrieve `[2, 3, 4]` from it we can use either:
<pre><code>a[<span style="color: blue">1</span> <span style="color: red">...</span> <span style="color: blue">3</span>]
<span style="color: gray; font-style: italic">== or</span>
a[<span style="color: blue">1</span> <span style="color: red">..</span> <span style="color: blue">4</span>]
</code></pre>

**Note:** concatenating two slices allocates a new array, which is no more sharing the elements with the original arrays.

If you skip one of the range bounds, one of the following two variants will be assumed:
- If the lower bound is skipped, the range starts at 0
- If the upper bound is skipped, the range ends at the last element's index
<pre><code>a <span style="color: red"><-</span> [<span style="color: blue">1</span>, <span style="color: blue">2</span>, <span style="color: blue">3</span>, <span style="color: blue">4</span>, <span style="color: blue">5</span>]
a[..<span style="color: blue">3</span>]  <span style="color: gray; font-style: italic">== [1, 2, 3]</span>
a[...<span style="color: blue">3</span>] <span style="color: gray; font-style: italic">== [1, 2, 3, 4]</span>
a[<span style="color: blue">1</span>..]  <span style="color: gray; font-style: italic">== [2, 3, 4] - the last element is not included!</span>
a[<span style="color: blue">1</span>...] <span style="color: gray; font-style: italic">== [2, 3, 4, 5]</span>
</code></pre>

**Note:** this applies only to array slicing. In other contexts no range bound can be skipped.


## Logical expressions
The literals are nothing fancy, just `true` and `false`.

Basic operations include conjunction a.k.a. AND (`a & b`), alternative a.k.a. OR (`a | b`), exclusive alternative a.k.a. XOR (`a @ b`), and negation a.k.a. NOT (`!a`). These operations, like in arithmetics, also have fixed precedences.
<pre><code>(a <span style="color: red">&</span> b <span style="color: red">|</span> <span style="color: red">!</span>c <span style="color: red">@</span> d) <span style="color: red">=</span> (a <span style="color: red">&</span> ((b <span style="color: red">|</span> <span style="color: red">!</span>c) <span style="color: red">@</span> d))
</code></pre>

Each of the binary logical operators has its negated counterpart:
- NOR `a !| b = !(a | b)`
- NAND `a !& b = !(a & b)`
- XNOR `a !@ b = !(a @ b)`

**Note:** `&`, `!&`, `|`, and `!|` are resolved lazily, i.e. whether the second operand is evaluated depends on the value of the first operand. Given `false & x`, `false !& x`, `true | x`, and `true !| x`, `x` is not evaluated since the value of `x` will not change the result of the operation anyway.

### Comparisons
You can compare values to each other, and the result of each comparison is always a boolean value.
<pre><code>a <span style="color: red">=</span>  b <span style="color: gray; font-style: italic">== a equal b</span>
a <span style="color: red">!=</span> b <span style="color: gray; font-style: italic">== a unequal b</span>
a <span style="color: red">></span>  b <span style="color: gray; font-style: italic">== a greater than b</span>
a <span style="color: red">>=</span> b <span style="color: gray; font-style: italic">== a greater than or equal b</span>
a <span style="color: red"><</span>  b <span style="color: gray; font-style: italic">== a less than b</span>
a <span style="color: red"><=</span> b <span style="color: gray; font-style: italic">== a less than or equal b</span>
</code></pre>

**Note:** comparisons other than for equality and inequality *must* be only between numeric types, otherwise it's an error.

**Note:** if two values are of different types, they are unequal (unlike in JavaScript where it may vary due to implicit type conversions).

Comparisons can be chained:
<pre><code>a <span style="color: red">=</span> b <span style="color: red">=</span> c <span style="color: gray; font-style: italic">== equivalent to: a = b & b = c</span>
a <span style="color: red"><</span> b <span style="color: red"><</span> c <span style="color: gray; font-style: italic">== equivalent to: a < b & b < c</span>
</code></pre>

You can check whether a number is in a certain range with the following notation:
<pre><code>value <span style="color: red">=</span> lower <span style="color: red">..</span> higher
<span style="color: gray; font-style: italic">== or, inclusively:</span>
value <span style="color: red">=</span> lower <span style="color: red">...</span> higher
</code></pre>

Testing if a value fits in a given error bar is also possible using the `+-` operator:
<pre><code>length in mm <span style="color: red">=</span> 33 <span style="color: red">+-</span> 1 <span style="color: gray; font-style: italic">== equivalent to: length in mm = 33 - 1 ... 33 + 1</span>
</code></pre>

### Conditional evaluation
Boolean values can be used as conditions for choosing between values. The syntax for conditional expressions is exactly the same as the ternary operator in most C-style programming languages.
<pre><code>age <span style="color: red">>=</span> <span style="color: blue">18</span> <span style="color: red">?</span> <span style="color: #66f">"adult"</span> <span style="color: red">:</span> <span style="color: #66f">"child"</span>
</code></pre>

For a switch-case-like code you can use nested conditional expressions.
<pre><code>fizz buzz <span style="color: red"><-</span> n <span style="color: red">%</span> <span style="color: blue">15</span> <span style="color: red">=</span> <span style="color: blue">0</span> <span style="color: red">?</span> <span style="color: #66f">"FizzBuzz"</span>
           <span style="color: red">:</span> n <span style="color: red">%</span> <span style="color: blue">3</span>  <span style="color: red">=</span> <span style="color: blue">0</span> <span style="color: red">?</span> <span style="color: #66f">"Fizz"</span>
           <span style="color: red">:</span> n <span style="color: red">%</span> <span style="color: blue">5</span>  <span style="color: red">=</span> <span style="color: blue">0</span> <span style="color: red">?</span> <span style="color: #66f">"Buzz"</span>
           <span style="color: red">:</span> n
</code></pre>

## Functions
They are the fundamental concept in functional programming. Functions can be created with the following syntax (obviously, without the comments below):
<pre><code>   is even (number) <span style="color: red">-></span> number <span style="color: red">%</span> <span style="color: blue">2</span> <span style="color: red">=</span> <span style="color: blue">0</span>
<span style="color: gray; font-style: italic">== \_____/ \______/    \____________/</span>
<span style="color: gray; font-style: italic">==    ↑       ↑               ↑</span>
<span style="color: gray; font-style: italic">==  name  parameters    return value</span>
</code></pre>

Which is the shorthand notation for:
<pre><code>is even <span style="color: red"><-</span> (number) <span style="color: red">-></span> number <span style="color: red">%</span> <span style="color: blue">2</span> <span style="color: red">=</span> <span style="color: blue">0</span>
<span style="color: gray; font-style: italic">==         \________________________/</span>
<span style="color: gray; font-style: italic">==                      ↑</span>
<span style="color: gray; font-style: italic">==       this alone is a function literal</span>
</code></pre>

More examples:
<pre><code>say hello () <span style="color: red">-></span> <span style="color: #66f">"Hello, world!"</span> <span style="color: gray; font-style: italic">== takes no parameters</span>
min (a, b) <span style="color: red">-></span> a <span style="color: red"><</span> b <span style="color: red">?</span> a <span style="color: red">:</span> b     <span style="color: gray; font-style: italic">== more than 1 parameters must be separated by commas</span>
</code></pre>

Functions can have local variables which are resolved before the return value. Simply list them in curly brackets after the closing parenthesis `)` and before the rightward arrow `->`, each separated with a comma.
<pre><code><span style="color: gray; font-style: italic">== possible implementation of the +- operator</span>
fits in error bar (number, error) {
    lower bound <span style="color: red"><-</span> number <span style="color: red">-</span> error,
    upper bound <span style="color: red"><-</span> number <span style="color: red">+</span> error
} <span style="color: red">-></span>
    lower bound <span style="color: red"><=</span> error <span style="color: red"><=</span> upper bound
</code></pre>

After creating a function you can call it just by inserting its name and the list of parameters inside following parentheses.
<pre><code>lesser <span style="color: red"><-</span> min (<span style="color: blue">5</span>, <span style="color: blue">10</span>) <span style="color: gray; font-style: italic">== 5</span>
<span style="color: gray; font-style: italic">== recursion is also supported:</span>
factorial (n) <span style="color: red">-></span>
    n <span style="color: red"><</span> <span style="color: blue">2</span> <span style="color: red">?</span> <span style="color: blue">1</span>
          <span style="color: red">:</span> n <span style="color: red">*</span> factorial (n <span style="color: red">-</span> <span style="color: blue">1</span>)
a lot <span style="color: red"><-</span> factorial (<span style="color: blue">9</span>) <span style="color: gray; font-style: italic">== 362880</span>
</code></pre>

### Lambdas
Functions, as all other values, can be passed as parameters, although you don't need to assign them to any variable to do that. What you can do is make use of anonymous functions, also known as lambda expressions. In fact, the function literal shown some sections above is a lambda expression.
<pre><code>filter (array, predicate) {
    no elements <span style="color: red"><-</span> array <span style="color: red">=</span> [],
    appended <span style="color: red"><-</span> <span style="color: red">!</span>no elements <span style="color: red">&</span> predicate (array[<span style="color: blue">0</span>]) <span style="color: red">?</span> [array[<span style="color: blue">0</span>]] <span style="color: red">:</span> []
} ->
    no elements <span style="color: red">?</span> [] <span style="color: red">:</span> appended <span style="color: red">~</span> filter (array[<span style="color: blue">1</span><span style="color: red">...</span>], predicate)

even numbers <span style="color: red"><-</span> filter ([<span style="color: blue">1</span>, <span style="color: blue">2</span>, <span style="color: blue">3</span>, <span style="color: blue">4</span>, <span style="color: blue">5</span>, <span style="color: blue">6</span>, <span style="color: blue">7</span>, <span style="color: blue">8</span>],
                        x <span style="color: red">-></span> x <span style="color: red">%</span> <span style="color: blue">2</span> <span style="color: red">=</span> <span style="color: blue">0</span>) <span style="color: gray; font-style: italic">== with exactly one argument no parentheses are required</span>
even numbers <span style="color: gray; font-style: italic">== [2, 4, 6, 8]</span>
</code></pre>


## Structures
(Still work in progress, yet some functionality is currently available.)

Structs are just packs of values, created with the following notation.
<pre><code>person <span style="color: red"><-</span> {
    name <span style="color: red"><-</span> <span style="color: #66f">"Adam"</span>,
    biological sex <span style="color: red"><<</span> <span style="color: #66f">"male"</span>,
    age <span style="color: red"><-</span> <span style="color: blue">20</span>,
    greet (other person's name) <span style="color: red">-></span> <span style="color: #66f">"Hello"</span> <span style="color: red">~</span> other person's name <span style="color: red">~</span> <span style="color: #66f">"!"</span>
}
</code></pre>

You can access fields using the `::` operator.
<pre><code>person <span style="color: red">::</span> greet (<span style="color: #66f">"Maciej"</span>) <span style="color: gray; font-style: italic">== prints: Hello, Maciej!</span>
person <span style="color: red">::</span> age <span style="color: red"><-</span> <span style="color: blue">21</span>
person <span style="color: red">::</span> biological sex <span style="color: red"><-</span> <span style="color: #66f">"female"</span> <span style="color: gray; font-style: italic">== error: the field `biological sex` is constant</span>
</code></pre>

New fields in a struct can be created simply by assigning to a previously unexistent field.