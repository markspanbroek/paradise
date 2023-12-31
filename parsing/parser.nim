import ./basics
import ./parslet
import ./grammar
import ./input

proc parse*(symbol: Symbol, input: Input): ?!char =
  let character = ? input.read()
  if symbol.character == character:
    success character
  else:
    char.failure "expected: '" & symbol.character & "'"

proc parse*[P: Parslet](parslet: P, input: string): auto =
  parslet.parse(Input.new(input))
