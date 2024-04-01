type
  LexerCategory* {.pure.} = enum
    number
    text
    name
    endOfInput
  LexerToken* = object
    case category*: LexerCategory:
    of number, text, name:
      value*: string
    else:
      discard

func `==`*(a, b: LexerToken): bool =
  if a.category != b.category:
    return false
  case a.category:
  of number, text, name:
    a.value == b.value
  else:
    true

func endOfInput*(_: type LexerToken): LexerToken =
  LexerToken(category: LexerCategory.endOfInput)
