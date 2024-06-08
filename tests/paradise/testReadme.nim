import std/unittest
import pkg/questionable
import pkg/questionable/results
import paradise

{.hint[XDeclaredButNotUsed]:off.}

suite "examples from readme":

  test "calculator":

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

    if outcome =? parser.parse("(1+1)*20+2*1"):
      # echo "Parse successful, outcome: ", outcome
      check outcome == 42
    else:
      # echo "Parse failed"
      fail()

  test "symbols":
    # match only the letter 'a'
    let letterA = symbol('a')

    # match only the letter 'b'
    let letterB = symbol('b')

    # match all letters 'a', 'b', 'c'....'z'
    let allLetters = symbol({'a'..'z'})

  test "concatenation":
    # match the string "abc"
    let abc = symbol('a') & symbol('b') & symbol('c')

  test "alternatives":
    let letter = symbol({'a'..'z'})
    let number = symbol({'0'..'9'})

    # match any letter or any number
    let letterOrNumber = letter | number

    let valid = (symbol('a') & symbol('b')) | (symbol('c') & symbol('d'))

    let invalid = (symbol('a') & symbol('b')) | (symbol('a') & symbol('c'))

  test "optional":
    # match the string "ab", but also "b"
    let ab = ?symbol('a') & symbol('b')

  test "repetition":
    # match "x", "xx", "xxx", etc, and also the empty string ""
    let zeroOrMore = *symbol('x')

    # match "x", "xx", "xxx", etc, but not the empty string
    let oneOrMore = +symbol('x')

  test "rules":
    rule digit: symbol({'0'..'9'})
    rule letter: symbol({'a'..'z'})

  test "recursion":
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

  test "end of input":
    let abc = symbol('a') & symbol('b') & symbol('c') & finish()
    let parser = abc.parser

    # parse succeeds, because "abc" occurs at the end
    let valid = parser.parse("abc")

    # parse fails, because "abc" is followed by "d"
    let invalid = parser.parse("abcd")

  test "conversion":
    # function that converts a digit char to an integer
    func convertDigit(parsed: char): int =
      parsed.int - '0'.int

    # use the conversion function when a digit is parsed
    let digit = symbol({'0'..'9'}) >> convertDigit

    let parser = digit.parser
    let number = parser.parse("4") # equals the integer 4

  test "tokenization":
    func convertName(parsed: (string, char)): string =
      parsed[0]

    let name = +symbol({'a'..'z'}) & (symbol(',') | finish()) >> convertName

    let parser = name.parser

    var output: seq[string]
    for token in parser.tokenize("foo,bar,baz"):
      # echo token # outputs first "foo", then "bar", and finally "baz"
      output.add(!token)

    check output == @["foo", "bar", "baz"]

  test "custom tokens, lexers and parsers":

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

    if outcome =? parser.parse(lexer.tokenize("(foo (bar 1 2) 3)")):
      # echo "Parse successful, outcome: ", outcome
      check outcome.kind == ExpressionKind.list
      check outcome.elements[0].kind == ExpressionKind.identifier
      check outcome.elements[1].kind == ExpressionKind.list
      check outcome.elements[2].kind == ExpressionKind.integer
    else:
      # echo "Parse failed"
      fail()
