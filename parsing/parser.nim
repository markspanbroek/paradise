import ./basics
import ./grammar
import ./input
import ./characters
import ./tuples
import ./LL1

type Parser*[G] = object
  grammar: G

proc parse*(symbol: Symbol, input: Input)
proc parse*(conversion: Conversion, input: Input)
proc parse*[C: Concatenation](concatenation: C, input: Input)
proc parse*(optional: Optional, input: Input)
proc parse*(rule: Recursion, input: Input)

proc parse*(symbol: Symbol, input: Input) =
  mixin category
  let peek = input.peek()
  without token =? peek:
    symbol.output =  peek
  if token.category in symbol.categories:
    symbol.output = input.read()
  else:
    symbol.output = typeof(token).failure "expected: " & $symbol & " " & $input.location()

proc parse*(conversion: Conversion, input: Input) =
  conversion.operand.parse(input)
  conversion.output = conversion.operand.output.map(conversion.convert)

proc parse*[C: Concatenation](concatenation: C, input: Input) =
  concatenation.left.parse(input)
  if concatenation.left.output.isSuccess:
    concatenation.right.parse(input)
  type Output = typeof(!concatenation.output)
  when concatenation.left is Concatenation:
    without left =? concatenation.left.output and
            right =? concatenation.right.output, error:
      concatenation.output = Output.failure error
      return
    concatenation.output = success left & right
  else:
    without left =? concatenation.left.output and
            right =? concatenation.right.output, error:
      concatenation.output = Output.failure error
      return
    concatenation.output = success (left, right)

proc parse*(optional: Optional, input: Input) =
  mixin category
  let operand = optional.operand
  type Output = typeof(!operand.output)
  without peek =? input.peek(), error:
    optional.output = failure(?Output, error)
    return
  if peek.category in operand.first:
    operand.parse(input)
    without value =? operand.output, error:
      optional.output = failure(?Output, error)
      return
    optional.output = success some value
  else:
    optional.output = success none Output

proc parse*(rule: Recursion, input: Input) =
  rule.parseClosure(input)

proc parse*(parser: Parser, input: Input): auto =
  parser.grammar.parse(input)
  parser.grammar.output

proc parser*[Token; G: Grammar[Token]](grammar: G): Parser[G] =
  grammar.update()
  Parser[G](grammar: grammar)

proc parse*[Token; G: Grammar[Token]](grammar: G, input: seq[Token]): auto =
  grammar.parser.parse(Input.new(input))

proc parse*[G: Grammar[char]](grammar: G, input: string): auto =
  grammar.parser.parse(Input.new(input))
