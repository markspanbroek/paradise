import ./basics
import ./grammar
import ./input
import ./characters
import ./tuples
import ./LL1

proc parse*(symbol: Symbol, input: Input): auto =
  mixin category
  let peek = input.peek()
  without token =? peek:
    return peek
  if token.category in symbol.categories:
    input.read()
  else:
    typeof(token).failure "expected: " & $symbol & " " & $input.location

proc parse*(conversion: Conversion, input: Input): auto =
  conversion.operand.parse(input).map(conversion.convert)

proc parse*[C: Concatenation](concatenation: C, input: Input): auto =
  when concatenation.left is Concatenation:
    without left =? concatenation.left.parse(input) and
            right =? concatenation.right.parse(input), error:
      type Output = typeof(left) & typeof(right)
      return Output.failure error
    success left & right
  else:
    without left =? concatenation.left.parse(input) and
            right =? concatenation.right.parse(input), error:
      type Output = (typeof(left), typeof(right))
      return Output.failure error
    success (left, right)

proc parse*(optional: Optional, input: Input): auto =
  mixin category
  let operand = optional.operand
  type Output = typeof(!operand.parse(input))
  without peek =? input.peek(), error:
    return failure(?Output, error)
  if peek.category in operand.first:
    without value =? operand.parse(input), error:
      return failure(?Output, error)
    success some value
  else:
    success none Output

proc parser*[Token; G: Grammar[Token]](grammar: G): auto =
  grammar.update()
  grammar

proc parse*[Token; G: Grammar[Token]](grammar: G, input: seq[Token]): auto =
  grammar.parser.parse(Input.new(input))

proc parse*[G: Grammar[char]](grammar: G, input: string): auto =
  grammar.parser.parse(Input.new(input))
