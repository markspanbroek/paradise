import ./basics
import ./grammar
import ./input
import ./characters
import ./tuples
import ./LL1

type Parser*[G] = object
  grammar: G

proc run*(symbol: Symbol, input: Input)
proc run*(conversion: Conversion, input: Input)
proc run*[C: Concatenation](concatenation: C, input: Input)
proc run*(optional: Optional, input: Input)
proc run*(rule: Recursion, input: Input)

proc run*(symbol: Symbol, input: Input) =
  mixin category
  let peek = input.peek()
  without token =? peek:
    symbol.output =  peek
  if token.category in symbol.categories:
    symbol.output = input.read()
  else:
    symbol.output = typeof(token).failure "expected: " & $symbol & " " & $input.location()

proc run*(conversion: Conversion, input: Input) =
  conversion.operand.run(input)
  conversion.output = conversion.operand.output.map(conversion.convert)

proc run*[C: Concatenation](concatenation: C, input: Input) =
  concatenation.left.run(input)
  if concatenation.left.output.isSuccess:
    concatenation.right.run(input)
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

proc run*(optional: Optional, input: Input) =
  mixin category
  let operand = optional.operand
  type Output = typeof(!operand.output)
  without peek =? input.peek(), error:
    optional.output = failure(?Output, error)
    return
  if peek.category in operand.first:
    operand.run(input)
    without value =? operand.output, error:
      optional.output = failure(?Output, error)
      return
    optional.output = success some value
  else:
    optional.output = success none Output

proc run*(rule: Recursion, input: Input) =
  rule.parseClosure(input)

proc parse*(parser: Parser, input: Input): auto =
  parser.grammar.run(input)
  parser.grammar.output

proc parser*[Token; G: Grammar[Token]](grammar: G): Parser[G] =
  grammar.update()
  Parser[G](grammar: grammar)

proc parse*[Token; G: Grammar[Token]](grammar: G, input: seq[Token]): auto =
  grammar.parser.parse(Input.new(input))

proc parse*[G: Grammar[char]](grammar: G, input: string): auto =
  grammar.parser.parse(Input.new(input))
