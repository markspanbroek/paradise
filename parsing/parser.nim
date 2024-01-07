import ./basics
import ./grammar
import ./input
import ./characters
import ./tuples

proc parse*[Token, Category](symbol: Symbol[Token, Category], input: Input): ?!Token =
  mixin category
  if (? input.peek()).category in symbol.categories:
    input.read()
  else:
    failure "expected: " & $symbol & " " & $input.location

proc parse*[Token, Category, Operand, From, To](conversion: Conversion[Token, Category, Operand, From, To], input: Input): ?!To =
  conversion.operand.parse(input).map(conversion.convert)

proc parse*[Token, Category, Left, Right](concatenation: Concatenation[Token, Category, Left, Right], input: Input): auto =
  when Left is Concatenation:
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

proc parse*[Token; G: Grammar[Token]](grammar: G, input: seq[Token]): auto =
  grammar.parse(Input.new(input))

proc parse*[G: Grammar[char]](grammar: G, input: string): auto =
  grammar.parse(Input.new(input))
