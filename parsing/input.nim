import ./basics
import ./characters

type Input*[Token] = concept input
  input.read() is ?!Token
  input.location() is string
  input.ended() is bool

type SequenceInput[Token] = ref object
  tokens: seq[Token]
  index: int
  location: int

func new*[Token](_: type Input, tokens: seq[Token]): SequenceInput[Token] =
  SequenceInput[Token](tokens: tokens, index: 0, location: 0)

proc location*(input: SequenceInput): string =
  "(" & $input.location & ")"

proc read*[Token](input: SequenceInput[Token]): ?!Token =
  mixin endOfInput
  if input.index < input.tokens.len:
    result = success input.tokens[input.index]
    inc input.index
    inc input.location
  elif input.index == input.tokens.len:
    result = success Token.endOfInput
    inc input.index
  else:
    result = failure "reading beyond end of input: " & location(input)

func ended*[Token](input: SequenceInput[Token]): bool =
  input.index >= input.tokens.len

type StringInput = ref object
  characters: string
  index: int
  location: (int, int)

func new*(_: type Input, characters: string): StringInput =
  StringInput(characters: characters, index: 0, location: (1, 1))

proc location*(input: StringInput): string =
  $input.location

proc read*(input: StringInput): ?!char =
  if input.index < input.characters.len:
    let character = input.characters[input.index]
    result = success character
    inc input.index
    if character == '\n':
      input.location = (input.location[0] + 1, 1)
    else:
      input.location = (input.location[0], input.location[1] + 1)
  elif input.index == input.characters.len:
    result = success '\0'
    inc input.index
  else:
    result = failure "reading beyond end of input: " & location(input)

func ended*(input: StringInput): bool =
  input.index >= input.characters.len
