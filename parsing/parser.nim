import ./basics
import ./parslet
import ./grammar
import ./input
import ./characters

proc parse*[Token, Category](symbol: Symbol[Token, Category], input: Input): ?!Token =
  mixin category
  let location = input.location
  let token = ? input.read()
  if token.category == symbol.category:
    success token
  else:
    Token.failure "expected: " & $symbol.category & " " & $location

proc parse*[Token; P: Parslet[Token]](parslet: P, input: seq[Token]): auto =
  parslet.parse(Input.new(input))

proc parse*[P: Parslet[char]](parslet: P, input: string): auto =
  parslet.parse(Input.new(input))
