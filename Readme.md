Paradise
========

A parsing library for LL(1) grammars.

Installation
------------

Use the [Nimble][1] package manager to add `paradise` to an existing
project. Add the following to its .nimble file:

```nim
requires "paradise >= 0.3.3 & < 0.4.0"
```

Example
-------

This example shows how to create a simple calculator that supports addition and
multiplication.

```nim
import paradise

# These functions convert parse results
# We declare them here, and define them later
func convertNumber(parsed: string): int
func convertParentheses(parsed: (char, int, char)): int
func convertProduct(parsed: (int, seq[(char, int)])): int
func convertSum(parsed: (int, seq[(char, int)])): int

# The grammar of our language:

# A number consists of one or more of the characters '0'..'9'
let number = +symbol({'0'..'9'}) >> convertNumber

# Parentheses allow for nesting of expressions,
# therefore we create a recursive rule
let parentheses = recursive int

# We can multiply either numbers or expressions in parentheses
let factor = number | parentheses

# We multipy one or more factors
let product = factor & *(symbol('*') & factor) >> convertProduct

# We add up one or more products
let sum = product & *(symbol('+') & product) >> convertSum

# The operator with the lowest precedence is the sum
let expression = sum

# Now we can define what parentheses are
define parentheses:
  symbol('(') & expression & symbol(')') >> convertParentheses

# Conversion functions:

# Convert decimal digits into an integer
func convertNumber(parsed: string): int =
  for digit in parsed:
    result *= 10
    result += digit.int - '0'.int

# Strip away parentheses
func convertParentheses(parsed: (char, int, char)): int =
  parsed[1]

# Calculate a product
func convertProduct(parsed: (int, seq[(char, int)])): int =
  result = parsed[0]
  for factor in parsed[1]:
    result *= factor[1]

# Calculate a sum
func convertSum(parsed: (int, seq[(char, int)])): int =
  result = parsed[0]
  for term in parsed[1]:
    result += term[1]

# Create a parser:

let parser = expression.parser

# Parse a string:

import questionable/results

if outcome =? parser.parse("(1+1)*20+2*1"):
  echo "Parse successful, outcome: ", outcome
else:
  echo "Parse failed"
```

Grammars
--------

A grammar defines what symbols can occur in a language and how they are
structured.

#### Symbols ####
Symbols can be defined with the `symbol` function:

```nim
# match only the letter 'a'
let letterA = symbol('a')

# match only the letter 'b'
let letterB = symbol('b')

# match all letters 'a', 'b', 'c'....'z'
let allLetters = symbol({'a'..'z'})
```

Returns the matched character when parsing succeeds.

#### Concatenation ####

You can concatenate two or more expressions with `&`:

```nim
# match the string "abc"
let abc = symbol('a') & symbol('b') & symbol('c')
```

Returns a tuple when parsing succeeds. The example above returns a tuple of type
`(char, char, char)`.

#### Alternatives ####

Alternatives are written using `|`:

```nim
let letter = symbol({'a'..'z'})
let number = symbol({'0'..'9'})

# match any letter or any number
let letterOrNumber = letter | number
```

With alternatives you need to be careful that the parser can make a decision on
which alternative to choose by looking at the next symbol. Otherwise the
language is not LL(1), and this parsing library does not support it.

For example, the following is a valid LL(1) grammar. The parser can tell the
difference between the left and right alternative by looking at the next symbol.
If it encounters an 'a', it chooses the left alternative, if it encounters a
'c', then it chooses the right alternative.

```nim
let valid = (symbol('a') & symbol('b')) | (symbol('c') & symbol('d'))
```

The following however is an invalid LL(1) grammar; both alternatives start with
the symbol 'a':

```nim
let invalid = (symbol('a') & symbol('b')) | (symbol('a') & symbol('c'))
```

#### Optional ####

Optional expressions are written using `?`:

```nim
# match the string "ab", but also "b"
let ab = ?symbol('a') & symbol('b')
```

Returns an `Option` when parsing succeeds. In the examples in this document we
use the [questionable][2] library to make working with optional values a bit
easier.

#### Repetition ####

Repetition is written using either `*` or `+`. Repetition with a `*` matches
zero or more instances, while repetition with `+` matches one or more instances.

```nim
# match "x", "xx", "xxx", etc, and also the empty string ""
let zeroOrMore = *symbol('x')

# match "x", "xx", "xxx", etc, but not the empty string
let oneOrMore = +symbol('x')
```

Returns a `seq` when parsing succeeds. For the examples above you would expect a
sequence of type `seq[char]`. Sequences of characters however are special and
are returned as `string` instead.

#### Rules ####

Grammar rules capture an expression and give it a name:

```nim
rule digit: symbol({'0'..'9'})
rule letter: symbol({'a'..'z'})
```

Giving expressions a name makes it easier to see what's wrong when a parse
fails, because the name is used in the error message.

#### Recursion ####

Recursive rules need to be declared first, and can then be defined later.

```nim
import questionable

# declare recursive rule, which after successful parsing returns an `int`
let parentheses = recursive int

# function that counts the number of matching parentheses
func count(parsed: (char, ?int, char)): int =
  if count =? parsed[1]:
    count + 1
  else:
    1

# define the recursive rule
define parentheses:
  symbol('(') & ?parentheses & symbol(')') >> count

# we can now count the number of matching parentheses in a string
let parser = parentheses.parser
let amount = parser.parse("((()))") # equals 3
```

#### End of input ####

It is possible to match the end of the input with `finish()` when you want to be
sure that there are no trailing characters after the matched input.

```nim
let abc = symbol('a') & symbol('b') & symbol('c') & finish()
let parser = abc.parser

# parse succeeds, because "abc" occurs at the end
let valid = parser.parse("abc")

# parse fails, because "abc" is followed by "d"
let invalid = parser.parse("abcd")
```

Returns the end of input character `'\0'` when parsing succeeds.

Conversion
----------

While parsing you can convert intermediate results into something else. This can
be useful for building a syntax tree, or for performing calculations as we've
seen in the calculator example.

Conversions are functions that take as input an intermediate result, and return
something else. The result can be of any type you choose. The `>>` operator is
then used to indicate where the conversion should to be applied.

```nim
# function that converts a digit char to an integer
func convertDigit(parsed: char): int =
  parsed.int - '0'.int

# use the conversion function when a digit is parsed
let digit = symbol({'0'..'9'}) >> convertDigit

let parser = digit.parser
let number = parser.parse("4") # equals the integer 4
```

Tokenization
------------

You can repeatedly match a grammar, to produce a stream of matched tokens.
Instead of calling the `parse` function, you would call the `tokenize` function.

To give an example, this is how you could match names separated by commas:

```nim
func convertName(parsed: (string, char)): string =
  parsed[0]

let name = +symbol({'a'..'z'}) & (symbol(',') | finish()) >> convertName

let parser = name.parser

for token in parser.tokenize("foo,bar,baz"):
  echo token # outputs first "foo", then "bar", and finally "baz"
```

Inputs
------

The `parse` and `tokenize` functions can take several kinds of input. In the
examples above we've used string inputs, but file inputs are supported as well.

We're not limited to parsing characters either. You can define a custom token
type, and define grammars that parse sequences of these tokens.

Custom tokens
-------------

Until now, we've only defined grammars that match characters, but you can also
define grammars that match custom tokens. This is especially useful when you
want to parse in two steps, such as a lexer-parser combination. The lexer first
parses characters and produces tokens which are then parsed by the parser.

Custom tokens need to have two properties defined so that we can build an LL(1)
parser for them, namely `category` and `endOfInput`.

Custom tokens can be of any type, but in order to support LL(1) sets we need to
have a type that can be stored in a Nim [`set`][3]. Therefore each custom token
needs to have a `category` property defined on it, so that the parser can store
that in a set.

The parser also needs a custom token to represent the end of the input. For
characters it uses `'\0'`, but for a custom type you need to define a value
yourself. The parser will use the `endOfInput` property of the token type.

Here's an example where we define both properties for a custom token type:

```nim
type
  # Our custom tokens fall into several categories
  LexerCategory {.pure.} = enum
    number
    name
    open
    close
    space
    endOfInput
  # Our custom token type
  LexerToken = object
    case category: LexerCategory # a category property that can be used in sets
    of number, name:
      value: string
    else:
      discard

# A custom token that represents the end of the input
func endOfInput(_: type LexerToken): LexerToken =
  LexerToken(category: LexerCategory.endOfInput)
```

Lexers and Parsers
------------------

We can use custom tokens and tokenization to create lexer-parser combinations.
The output of the lexer is used as input for the parser.

The following example parses a Lisp program in two steps. First, the lexer
recognizes numbers, text, names and parentheses and turns them into tokens. As a
second step the parser takes the output from the lexer and recognizes lists, and
turns them into Lisp expressions.

First we define the lexer that produces tokens. We use the `LexerToken` that
we've defined above.

```nim
func convertNumber(parsed: string): LexerToken =
  LexerToken(category: LexerCategory.number, value: parsed)

func convertName(parsed: string): LexerToken =
  LexerToken(category: LexerCategory.name, value: parsed)

func convertOpen(_: char): LexerToken =
  LexerToken(category: LexerCategory.open)

func convertClose(_: char): LexerToken =
  LexerToken(category: LexerCategory.close)

func convertSpace(_: char): LexerToken =
  LexerToken(category: LexerCategory.space)

let number = +symbol({'0'..'9'}) >> convertNumber
let name = +symbol({'a'..'z', 'A'..'Z'}) >> convertName
let open = symbol('(') >> convertOpen
let close = symbol(')') >> convertClose
let space = symbol(' ') >> convertSpace
let token = number | name | open | close | space

let lexer = token.parser
```

Now we can define the parser whose grammar is based on the tokens that the lexer
produces.

```nim
type
  ExpressionKind {.pure.} = enum
    identifier
    integer
    list
  Expression = object
    case kind: ExpressionKind
    of identifier:
      name: string
    of integer:
      value: int
    of list:
      elements: seq[Expression]

func convertIdentifier(parsed: LexerToken): Expression =
  Expression(kind: ExpressionKind.identifier, name: parsed.value)

func convertLiteral(parsed: LexerToken): Expression =
  var value = 0
  for digit in parsed.value:
    value *= 10
    value += digit.int - '0'.int
  Expression(kind: ExpressionKind.integer, value: value)

func convertElements(parsed: (Expression, seq[(LexerToken, Expression)])): seq[Expression] =
  result.add(parsed[0])
  for values in parsed[1]:
    result.add(values[1])

func convertList(parsed: (LexerToken, seq[Expression], LexerToken)): Expression =
  result = Expression(kind: ExpressionKind.list)
  result.elements = parsed[1]

let identifier = symbol(LexerToken, LexerCategory.name) >> convertIdentifier
let integer = symbol(LexerToken, LexerCategory.number) >> convertLiteral
let listOpen = symbol(LexerToken, LexerCategory.open)
let listClose = symbol(LexerToken, LexerCategory.close)
let separator = symbol(LexerToken, LexerCategory.space)
let expression = recursive(LexerToken, Expression)
let elements = expression & *(separator & expression) >> convertElements
let list = listOpen & elements & listClose >> convertList
define expression: identifier | integer | list

let parser = expression.parser
```

And then we can use the lexer and parser combined to parse Lisp expressions:

```nim
import questionable/results

if outcome =? parser.parse(lexer.tokenize("(foo (bar 1 2) 3)")):
  echo "Parse successful, outcome: ", outcome
else:
  echo "Parse failed"
```

[1]: https://github.com/nim-lang/nimble
[2]: https://github.com/codex-storage/questionable
[3]: https://nim-lang.org/docs/manual.html#types-set-type
