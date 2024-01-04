import ./basics
import ./grammar
import ./input
import ./characters

proc parse*[Token, Category](symbol: Symbol[Token, Category], input: Input[Token]): ?!Token =
  mixin category
  let location = input.location
  let token = ? input.read()
  if token.category in symbol.categories:
    success token
  else:
    Token.failure "expected: " & $symbol & " " & location

proc parse*[Token, Operand, From, To](conversion: Conversion[Token, Operand, From, To], input: Input[Token]): ?!To =
  conversion.operand.parse(input).map(conversion.convert)

proc parse*[Token](parslet: Parslet[Token], input: seq[Token]): auto =
  parslet.parse(Input.new(input))

proc parse*(parslet: Parslet[char], input: string): auto =
  parslet.parse(Input.new(input))

iterator parse*[Token](parslet: Parslet[Token], input: Input[Token]): auto =
  var failure = false
  while not input.ended() and not failure:
    let parsed = parslet.parse(input)
    failure = parsed.isFailure
    yield parsed

iterator parse*[Token](parslet: Parslet[Token], input: seq[Token]): auto =
  let input = Input.new(input)
  for parsed in parslet.parse(input):
    yield parsed

iterator parse*(parslet: Parslet[char], input: string): auto =
  let input = Input.new(input)
  for parsed in parslet.parse(input):
    yield parsed
