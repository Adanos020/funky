<link rel="stylesheet" href="README-style.css">

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
<pre><code><span class="code-string">"Hello, world!"</span>
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
<pre><code><span class="code-keyword">import</span> <span class="code-string">std/math/constants</span> <span class="code-comment">== imports the module "std/math/constants.f"</span>
<span class="code-keyword">import</span> <span class="code-string">std/math</span>           <span class="code-comment">== imports all modules in "std/math/"</span>
</code></pre>


## Comments
Funky supports only single line comments.
<pre><code><span class="code-comment">== Everyone ignores me</span>
</code></pre>


## Variables
In order to create or assign to a variable, simply insert its name, a leftward arrow `<-`, and the value.
<pre><code>some number <span class="code-operator"><-</span> <span class="code-number">10</span>
</code></pre>

You can also create constants, you only need to insert a double leftward arrow `<<` instead of the single one. **Note:** you cannot reassign to a constant!
<pre><code>GRAVITATIONAL CONSTANT <span class="code-operator"><<</span> <span class="code-number">6.67408e-10</span>
GRAVITATIONAL CONSTANT <span class="code-operator"><<</span> <span class="code-number">7</span> <span class="code-comment">== error!</span>
</code></pre>

What you can do, though, is to change a variable into a constant.
<pre><code>thank the bus driver <span class="code-operator"><-</span> <span class="code-keyword">false</span>
thank the bus driver <span class="code-operator"><<</span> <span class="code-keyword">true</span> <span class="code-comment">== ok and very wholesome</span>
</code></pre>

Funky is dynamically typed, meaning that a variable can change its value type on the fly.
<pre><code>bipolar <span class="code-operator"><-</span> <span class="code-number">2</span>
bipolar <span class="code-operator"><-</span> <span class="code-number">"who am I"</span>
</code></pre>


## Arithmetics
To make a number literal, simply insert digits. You can insert a decimal point if you need too. In longer numbers you can insert spaces for readability (as in identifiers, number of spaces is ignored).
<pre><code>dozen <span class="code-operator"><-</span> <span class="code-number">12</span>
PI <span class="code-operator"><<</span> <span class="code-number">3.14 159 265 359</span>
</code></pre>

Scientific notation is supported too.
<pre><code>kilo <span class="code-operator"><-</span> <span class="code-number">1e3</span>
micro <span class="code-operator"><-</span> <span class="code-number">1e-6</span>
approximate world population <span class="code-operator"><-</span> <span class="code-number">7.7e+9</span> <span class="code-comment">== the `+` doesn't change anything, it's just there</span>
</code></pre>

There are also special literals for infinity `inf` and not a number `nan`.

Arithmetic operations include addition (`a + b`), subtraction (`a - b`), multiplication (`a * b`), division (`a / b`), modulo (remainder of division) (`a % b`), powers (`a ^ b`), and negation (`-a`).

All these operations have their fixed precedence, due to which the following expression:
<pre><code><span class="code-number">4</span> <span class="code-operator">+</span> <span class="code-operator">-</span><span class="code-number">3</span> <span class="code-operator">^</span> <span class="code-number">2</span> <span class="code-operator">*</span> (<span class="code-number">6</span> <span class="code-operator">-</span> <span class="code-number">1</span>) <span class="code-operator">/</span> <span class="code-number">5</span>
</code></pre>

will be evaluated like this:
<pre><code><span class="code-number">4</span> <span class="code-operator">+</span> ((<span class="code-operator">-</span><span class="code-number">3</span>) <span class="code-operator">^</span> <span class="code-number">2</span>) <span class="code-operator">*</span> ((<span class="code-number">6</span> <span class="code-operator">-</span> <span class="code-number">1</span>) <span class="code-operator">/</span> <span class="code-number">5</span>)
</code></pre>

## Strings

A string literal is composed of any string of characters surrounded by two quotation marks, `"like this"`.

If you want to insert a quotation mark inside a string, you need to insert a backslash before it: `"as Einstein said someday: \"no\"."`.

Because backslash makes its following character escaped, to insert an actual backslash in a string you got to insert two of them, right next to each other: `"this is a backslash: \\"`.

To join two strings together simply insert the `~` character between both of them.
<pre><code>greeting  <span class="code-operator"><-</span> <span class="code-string">"Hello"</span>
addressee <span class="code-operator"><-</span> <span class="code-string">"world"</span>
message   <span class="code-operator"><-</span> greeting <span class="code-operator">~</span> <span class="code-string">", "</span> <span class="code-operator">~</span> addressee <span class="code-operator">~</span> <span class="code-string">"!"</span>
</code></pre>

You can also join other types of values, provided a string is the first in the chain. Joined values will automatically be converted into a string.
<pre><code><span class="code-string">"Stay hydrated, "</span> <span class="code-operator">~</span> <span class="code-number">820</span> <span class="code-operator">~</span> <span class="code-string">" pal"</span> <span class="code-comment">== prints "Stay hydrated, 820 pal"</span>
</code></pre>

(String slicing and indexing is still work in progress.)


## Arrays
To create an array of values simply insert square brackets and list all the values, separated by commas. Values of different types can be stored in one array.
<pre><code>some random array <span class="code-operator"><-</span> [<span class="code-number">21</span>, <span class="code-number">37</span>, <span class="code-string">"those are totally random numbers"</span>, <span class="code-keyword">true</span>]
</code></pre>

You can easily access the elements of an array by inserting square brackets after it, and an index value inside, where 0 stands for the first element. Negative indices mean to start indexing from the last element (for which stands -1).
<pre><code>prime numbers <span class="code-operator"><-</span> [<span class="code-number">2</span>, <span class="code-number">3</span>, <span class="code-number">5</span>, <span class="code-number">7</span>, <span class="code-number">11</span>, <span class="code-number">13</span>]
prime numbers[<span class="code-number">0</span>]  <span class="code-comment">== 2</span>
prime numbers[<span class="code-number">2</span>]  <span class="code-comment">== 5</span>
prime numbers[-<span class="code-number">1</span>] <span class="code-comment">== 13</span>
</code></pre>

**Note:** any index outside the array bounds is an error.

Each element can be assigned to as follows.
<pre><code>array <span class="code-operator"><-</span> [<span class="code-number">1</span>, <span class="code-number">9</span>, <span class="code-number">8</span>, <span class="code-number">4</span>]
array[<span class="code-operator">-</span><span class="code-number">2</span>] <span class="code-operator"><-</span> <span class="code-number">9</span>
array <span class="code-comment">== prints [1, 9, 9, 4]</span>
</code></pre>

### Array slicing
You can join arrays exactly like strings, with a small exception. Joining different values will simply add them to the preceding array.
<pre><code>numbers again <span class="code-operator"><-</span> [<span class="code-number">1</span>, <span class="code-number">1</span>, <span class="code-number">2</span>, <span class="code-number">3</span>, <span class="code-number">5</span>, <span class="code-number">8</span>, <span class="code-number">13</span>]
and     again <span class="code-operator"><-</span> numbers again <span class="code-operator">~</span> [<span class="code-number">21</span>, <span class="code-number">34</span>, <span class="code-number">55</span>] <span class="code-comment">== [1, 1, 2, 3, 5, 8, 13, 21, 34, 55]</span>
and yet again <span class="code-operator"><-</span> and again <span class="code-operator">~</span> <span class="code-number">89</span> <span class="code-operator">~</span> <span class="code-number">154</span>         <span class="code-comment">== [1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 154]</span>
<span class="code-comment">== oh what a nice square shape I made here</span>
</code></pre>

You can also slice arrays, i.e. take their smaller parts and treat them as new arrays... kinda. They are in fact just new references to a part of the original array, so changing a value in a slice changes the value in the array from which the slice was taken.

To get a slice, use a similar notation as in indexing, except instead of indices use numerical ranges. There are two types of numerical ranges in Funky: upper-inclusive and upper-exclusive, meaning that the upper bound can be either included in or excluded out of the range. The notation for both types of ranges looks like this:
<pre><code>lower <span class="code-operator">...</span> upper <span class="code-comment">== upper-inclusive, corresponds to mathematical [lower, upper]</span>
lower <span class="code-operator">..</span>  upper <span class="code-comment">== upper-exclusive, corresponds to mathematical [lower, upper)</span>
</code></pre>

**Note:** the lower bound in array slicing must be actually lower than the upper, otherwise it's an error. In other contexts it may vary.

So given an array named `a` with values `[1, 2, 3, 4, 5]`, to retrieve `[2, 3, 4]` from it we can use either:
<pre><code>a[<span class="code-number">1</span> <span class="code-operator">...</span> <span class="code-number">3</span>]
<span class="code-comment">== or</span>
a[<span class="code-number">1</span> <span class="code-operator">..</span> <span class="code-number">4</span>]
</code></pre>

**Note:** concatenating two slices allocates a new array, which is no more sharing the elements with the original arrays.

If you skip one of the range bounds, one of the following two variants will be assumed:
- If the lower bound is skipped, the range starts at 0
- If the upper bound is skipped, the range ends at the last element's index
<pre><code>a <span class="code-operator"><-</span> [<span class="code-number">1</span>, <span class="code-number">2</span>, <span class="code-number">3</span>, <span class="code-number">4</span>, <span class="code-number">5</span>]
a[..<span class="code-number">3</span>]  <span class="code-comment">== [1, 2, 3]</span>
a[...<span class="code-number">3</span>] <span class="code-comment">== [1, 2, 3, 4]</span>
a[<span class="code-number">1</span>..]  <span class="code-comment">== [2, 3, 4] - the last element is not included!</span>
a[<span class="code-number">1</span>...] <span class="code-comment">== [2, 3, 4, 5]</span>
</code></pre>

**Note:** this applies only to array slicing. In other contexts no range bound can be skipped.


## Logical expressions
The literals are nothing fancy, just `true` and `false`.

Basic operations include conjunction a.k.a. AND (`a & b`), alternative a.k.a. OR (`a | b`), exclusive alternative a.k.a. XOR (`a @ b`), and negation a.k.a. NOT (`!a`). These operations, like in arithmetics, also have fixed precedences.
<pre><code>(a <span class="code-operator">&</span> b <span class="code-operator">|</span> <span class="code-operator">!</span>c <span class="code-operator">@</span> d) <span class="code-operator">=</span> (a <span class="code-operator">&</span> ((b <span class="code-operator">|</span> <span class="code-operator">!</span>c) <span class="code-operator">@</span> d))
</code></pre>

Each of the binary logical operators has its negated counterpart:
- NOR `a !| b = !(a | b)`
- NAND `a !& b = !(a & b)`
- XNOR `a !@ b = !(a @ b)`

**Note:** `&`, `!&`, `|`, and `!|` are resolved lazily, i.e. whether the second operand is evaluated depends on the value of the first operand. Given `false & x`, `false !& x`, `true | x`, and `true !| x`, `x` is not evaluated since the value of `x` will not change the result of the operation anyway.

### Comparisons
You can compare values to each other, and the result of each comparison is always a boolean value.
<pre><code>a <span class="code-operator">=</span>  b <span class="code-comment">== a equal b</span>
a <span class="code-operator">!=</span> b <span class="code-comment">== a unequal b</span>
a <span class="code-operator">></span>  b <span class="code-comment">== a greater than b</span>
a <span class="code-operator">>=</span> b <span class="code-comment">== a greater than or equal b</span>
a <span class="code-operator"><</span>  b <span class="code-comment">== a less than b</span>
a <span class="code-operator"><=</span> b <span class="code-comment">== a less than or equal b</span>
</code></pre>

**Note:** comparisons other than for equality and inequality *must* be only between numeric types, otherwise it's an error.

**Note:** if two values are of different types, they are unequal (unlike in JavaScript where it may vary due to implicit type conversions).

Comparisons can be chained:
<pre><code>a <span class="code-operator">=</span> b <span class="code-operator">=</span> c <span class="code-comment">== equivalent to: a = b & b = c</span>
a <span class="code-operator"><</span> b <span class="code-operator"><</span> c <span class="code-comment">== equivalent to: a < b & b < c</span>
</code></pre>

You can check whether a number is in a certain range with the following notation:
<pre><code>value <span class="code-operator">=</span> lower <span class="code-operator">..</span> higher
<span class="code-comment">== or, inclusively:</span>
value <span class="code-operator">=</span> lower <span class="code-operator">...</span> higher
</code></pre>

Testing if a value fits in a given error bar is also possible using the `+-` operator:
<pre><code>length in mm <span class="code-operator">=</span> 33 <span class="code-operator">+-</span> 1 <span class="code-comment">== equivalent to: length in mm = 33 - 1 ... 33 + 1</span>
</code></pre>

### Conditional evaluation
Boolean values can be used as conditions for choosing between values. The syntax for conditional expressions is exactly the same as the ternary operator in most C-style programming languages.
<pre><code>age <span class="code-operator">>=</span> <span class="code-number">18</span> <span class="code-operator">?</span> <span class="code-string">"adult"</span> <span class="code-operator">:</span> <span class="code-string">"child"</span>
</code></pre>

For a switch-case-like code you can use nested conditional expressions.
<pre><code>fizz buzz <span class="code-operator"><-</span> n <span class="code-operator">%</span> <span class="code-number">15</span> <span class="code-operator">=</span> <span class="code-number">0</span> <span class="code-operator">?</span> <span class="code-string">"FizzBuzz"</span>
           <span class="code-operator">:</span> n <span class="code-operator">%</span> <span class="code-number">3</span>  <span class="code-operator">=</span> <span class="code-number">0</span> <span class="code-operator">?</span> <span class="code-string">"Fizz"</span>
           <span class="code-operator">:</span> n <span class="code-operator">%</span> <span class="code-number">5</span>  <span class="code-operator">=</span> <span class="code-number">0</span> <span class="code-operator">?</span> <span class="code-string">"Buzz"</span>
           <span class="code-operator">:</span> n
</code></pre>

## Functions
They are the fundamental concept in functional programming. Functions can be created with the following syntax (obviously, without the comments below):
<pre><code>   is even (number) <span class="code-operator">-></span> number <span class="code-operator">%</span> <span class="code-number">2</span> <span class="code-operator">=</span> <span class="code-number">0</span>
<span class="code-comment">== \_____/ \______/    \____________/</span>
<span class="code-comment">==    ↑       ↑               ↑</span>
<span class="code-comment">==  name  parameters    return value</span>
</code></pre>

Which is the shorthand notation for:
<pre><code>is even <span class="code-operator"><-</span> (number) <span class="code-operator">-></span> number <span class="code-operator">%</span> <span class="code-number">2</span> <span class="code-operator">=</span> <span class="code-number">0</span>
<span class="code-comment">==         \________________________/</span>
<span class="code-comment">==                      ↑</span>
<span class="code-comment">==       this alone is a function literal</span>
</code></pre>

More examples:
<pre><code>say hello () <span class="code-operator">-></span> <span class="code-string">"Hello, world!"</span> <span class="code-comment">== takes no parameters</span>
min (a, b) <span class="code-operator">-></span> a <span class="code-operator"><</span> b <span class="code-operator">?</span> a <span class="code-operator">:</span> b     <span class="code-comment">== more than 1 parameters must be separated by commas</span>
</code></pre>

Functions can have local variables which are resolved before the return value. Simply list them in curly brackets after the closing parenthesis `)` and before the rightward arrow `->`, each separated with a comma.
<pre><code><span class="code-comment">== possible implementation of the +- operator</span>
fits in error bar (number, error) {
    lower bound <span class="code-operator"><-</span> number <span class="code-operator">-</span> error,
    upper bound <span class="code-operator"><-</span> number <span class="code-operator">+</span> error
} <span class="code-operator">-></span>
    lower bound <span class="code-operator"><=</span> error <span class="code-operator"><=</span> upper bound
</code></pre>

After creating a function you can call it just by inserting its name and the list of parameters inside following parentheses.
<pre><code>lesser <span class="code-operator"><-</span> min (<span class="code-number">5</span>, <span class="code-number">10</span>) <span class="code-comment">== 5</span>
<span class="code-comment">== recursion is also supported:</span>
factorial (n) <span class="code-operator">-></span>
    n <span class="code-operator"><</span> <span class="code-number">2</span> <span class="code-operator">?</span> <span class="code-number">1</span>
          <span class="code-operator">:</span> n <span class="code-operator">*</span> factorial (n <span class="code-operator">-</span> <span class="code-number">1</span>)
a lot <span class="code-operator"><-</span> factorial (<span class="code-number">9</span>) <span class="code-comment">== 362880</span>
</code></pre>

### Lambdas
Functions, as all other values, can be passed as parameters, although you don't need to assign them to any variable to do that. What you can do is make use of anonymous functions, also known as lambda expressions. In fact, the function literal shown some sections above is a lambda expression.
<pre><code>filter (array, predicate) {
    no elements <span class="code-operator"><-</span> array <span class="code-operator">=</span> [],
    appended <span class="code-operator"><-</span> <span class="code-operator">!</span>no elements <span class="code-operator">&</span> predicate (array[<span class="code-number">0</span>]) <span class="code-operator">?</span> [array[<span class="code-number">0</span>]] <span class="code-operator">:</span> []
} ->
    no elements <span class="code-operator">?</span> [] <span class="code-operator">:</span> appended <span class="code-operator">~</span> filter (array[<span class="code-number">1</span><span class="code-operator">...</span>], predicate)

even numbers <span class="code-operator"><-</span> filter ([<span class="code-number">1</span>, <span class="code-number">2</span>, <span class="code-number">3</span>, <span class="code-number">4</span>, <span class="code-number">5</span>, <span class="code-number">6</span>, <span class="code-number">7</span>, <span class="code-number">8</span>],
                        x <span class="code-operator">-></span> x <span class="code-operator">%</span> <span class="code-number">2</span> <span class="code-operator">=</span> <span class="code-number">0</span>) <span class="code-comment">== with exactly one argument no parentheses are required</span>
even numbers <span class="code-comment">== [2, 4, 6, 8]</span>
</code></pre>


## Structures
(Still work in progress, yet some functionality is currently available.)

Structs are just packs of values, created with the following notation.
<pre><code>person <span class="code-operator"><-</span> {
    name <span class="code-operator"><-</span> <span class="code-string">"Adam"</span>,
    biological sex <span class="code-operator"><<</span> <span class="code-string">"male"</span>,
    age <span class="code-operator"><-</span> <span class="code-number">20</span>,
    greet (other person's name) <span class="code-operator">-></span> <span class="code-string">"Hello"</span> <span class="code-operator">~</span> other person's name <span class="code-operator">~</span> <span class="code-string">"!"</span>
}
</code></pre>

You can access fields using the `::` operator.
<pre><code>person <span class="code-operator">::</span> greet (<span class="code-string">"Maciej"</span>) <span class="code-comment">== prints: Hello, Maciej!</span>
person <span class="code-operator">::</span> age <span class="code-operator"><-</span> <span class="code-number">21</span>
person <span class="code-operator">::</span> biological sex <span class="code-operator"><-</span> <span class="code-string">"female"</span> <span class="code-comment">== error: the field `biological sex` is constant</span>
</code></pre>

New fields in a struct can be created simply by assigning to a previously unexistent field.