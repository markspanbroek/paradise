import ./lexer

proc charToInt*(character: char): int =
  character.int - '0'.int

proc tokenToString*(token: LexerToken): string =
  case token.category
  of number, text:
    token.value
  else:
    $token.category
