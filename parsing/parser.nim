import ./basics
import ./grammar
import ./input
import ./characters

proc parse*[Token, Category](symbol: Symbol[Token, Category], input: Input): ?!Token =
  mixin category
  let location = input.location
  let token = ? input.read()
  if token.category in symbol.categories:
    success token
  else:
    Token.failure "expected: " & $symbol & " " & location

proc parse*[Token, Operand, From, To](conversion: Conversion[Token, Operand, From, To], input: Input): ?!To =
  conversion.operand.parse(input).map(conversion.convert)

proc parse*[Token](parslet: Parslet[Token], input: seq[Token]): auto =
  parslet.parse(Input.new(input))

proc parse*(parslet: Parslet[char], input: string): auto =
  parslet.parse(Input.new(input))
