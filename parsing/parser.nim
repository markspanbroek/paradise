import ./basics
import ./grammar
import ./input
import ./characters
import ./tuples
import ./LL1

proc run(symbol: Symbol, input: Input)
proc run(conversion: Conversion, input: Input)
proc run[C: Concatenation](concatenation: C, input: Input)
proc run(optional: Optional, input: Input)
proc run(rule: Recursion, input: Input)

proc parse*(grammar: Grammar, input: Input): auto =
  grammar.run(input)
  result = grammar.output
  grammar.output.reset()

proc run(symbol: Symbol, input: Input) =
  mixin category
  let peek = input.peek()
  without token =? peek:
    symbol.output =  peek
  if token.category in symbol.categories:
    symbol.output = input.read()
  else:
    symbol.output = typeof(token).failure "expected: " & $symbol & " " & $input.location()

proc run(conversion: Conversion, input: Input) =
  conversion.output = conversion.operand.parse(input).map(conversion.convert)

proc run[C: Concatenation](concatenation: C, input: Input) =
  type Output = typeof(!concatenation.output)
  without left =? concatenation.left.parse(input) and
          right =? concatenation.right.parse(input), error:
    concatenation.output = Output.failure error
    return
  when concatenation.left is Concatenation:
    concatenation.output = success left & right
  else:
    concatenation.output = success (left, right)

proc run(optional: Optional, input: Input) =
  mixin category
  let operand = optional.operand
  type Output = typeof(!operand.output)
  without peek =? input.peek(), error:
    optional.output = failure(?Output, error)
    return
  if peek.category in operand.first:
    without value =? operand.parse(input), error:
      optional.output = failure(?Output, error)
      return
    optional.output = success some value
  else:
    optional.output = success none Output

proc run(rule: Recursion, input: Input) =
  rule.runClosure(input)

type Parser*[G] = object
  grammar: G

func parser*(grammar: Grammar): auto =
  grammar.update()
  Parser[typeof(grammar)](grammar: grammar)

proc parse*(parser: Parser, input: Input): auto =
  parser.grammar.parse(input)

proc parse*[G: Grammar[char]](parser: Parser[G], input: string): auto =
  parser.parse(Input.new(input))

proc parse*[Token; G: Grammar[Token]](parser: Parser[G], input: seq[Token]): auto =
  parser.parse(Input.new(input))

template parse*(grammar: Grammar, input: untyped): auto =
  grammar.parser.parse(input)
