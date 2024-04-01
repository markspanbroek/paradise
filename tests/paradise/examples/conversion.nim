import ./lexer

proc charToInt*(character: char): int =
  if character in {'0'..'9'}:
    character.int - '0'.int
  else:
    -1

proc tokenToString*(token: LexerToken): string =
  case token.category
  of number, text:
    token.value
  else:
    $token.category
