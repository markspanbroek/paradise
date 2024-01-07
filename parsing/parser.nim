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
    Token.failure "expected: " & $symbol & " " & $input.location

proc parse*[Token, Operand, From, To](conversion: Conversion[Token, Operand, From, To], input: Input): ?!To =
  conversion.operand.parse(input).map(conversion.convert)

proc parse*[Token, Left, Right](concatenation: Concatenation[Token, Left, Right], input: Input): auto =
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

proc parse*[Token; P: Parslet[Token]](parslet: P, input: seq[Token]): auto =
  parslet.parse(Input.new(input))

proc parse*[P: Parslet[char]](parslet: P, input: string): auto =
  parslet.parse(Input.new(input))
