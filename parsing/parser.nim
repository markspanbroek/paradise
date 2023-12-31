import ./basics
import ./parslet
import ./grammar
import ./input
import ./characters

proc parse*[Token, Category](symbol: Symbol[Token, Category], input: Input[Token]): ?!Token =
  mixin category
  let token = ? input.read()
  if token.category == symbol.category:
    success token
  else:
    Token.failure "expected: " & $symbol.category

proc parse*[Token; P: Parslet[Token]](parslet: P, input: seq[Token]): auto =
  parslet.parse(Input.new(input))

proc parse*[P: Parslet[char]](parslet: P, input: string): auto =
  parslet.parse(Input.new(input))
