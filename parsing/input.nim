import ./basics
import ./characters

type Input*[Token] = ref object of RootObj

type SequenceInput[Token] = ref object of Input[Token]
  tokens: seq[Token]
  index: int
  location: int

func new*[Token](_: type Input, tokens: seq[Token]): SequenceInput[Token] =
  SequenceInput[Token](tokens: tokens, index: 0, location: 0)

proc location*(input: SequenceInput): string =
  "(" & $input.location & ")"

proc peek*[Token](input: SequenceInput[Token]): ?!Token =
  mixin endOfInput
  if input.index < input.tokens.len:
    result = success input.tokens[input.index]
  elif input.index == input.tokens.len:
    result = success Token.endOfInput
  else:
    result = failure "reading beyond end of input: " & location(input)

proc read*[Token](input: SequenceInput[Token]): ?!Token =
  result = input.peek()
  if result.isSuccess:
    if input.index < input.tokens.len:
      inc input.location
    inc input.index

func ended*[Token](input: SequenceInput[Token]): bool =
  input.index >= input.tokens.len

type StringInput = ref object of Input[char]
  characters: string
  index: int
  location: (int, int)

func new*(_: type Input, characters: string): StringInput =
  StringInput(characters: characters, index: 0, location: (1, 1))

proc location*(input: StringInput): string =
  $input.location

proc peek*(input: StringInput): ?!char =
  if input.index < input.characters.len:
    let character = input.characters[input.index]
    result = success character
  elif input.index == input.characters.len:
    result = success '\0'
  else:
    result = failure "reading beyond end of input: " & location(input)

proc read*(input: StringInput): ?!char =
  result = input.peek()
  if result.isSuccess:
    if input.index < input.characters.len:
      if !result == '\n':
        input.location = (input.location[0] + 1, 1)
      else:
        input.location = (input.location[0], input.location[1] + 1)
    inc input.index

func ended*(input: StringInput): bool =
  input.index >= input.characters.len

iterator items*(input: Input): auto =
  var failure = false
  while not input.ended() and not failure:
    let item = input.read()
    failure = item.isFailure
    yield item
