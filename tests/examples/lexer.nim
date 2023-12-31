type
  LexerCategory* {.pure.} = enum
    number
    text
    endOfInput
  LexerToken* = object
    case category*: LexerCategory:
    of number, text:
      value*: string
    else:
      discard

func `==`*(a, b: LexerToken): bool =
  if a.category != b.category:
    return false
  case a.category:
  of number, text:
    a.value == b.value
  else:
    true

func endOfInput*(_: type LexerToken): LexerToken =
  LexerToken(category: LexerCategory.endOfInput)
