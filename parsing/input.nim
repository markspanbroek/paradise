import ./basics
import ./characters

type
  Input*[Token] = ref object of RootObj
    location*: Location
  Location = object
    line: int
    column: int

func `$`*(location: Location): string =
  "(" & $location.line & ", " & $location.column & ")"

type
  SequenceInput[Token] = ref object of Input[Token]
    tokens: seq[Token]
    index: int

func new*[Token](_: type Input, tokens: seq[Token]): SequenceInput[Token] =
  let location = Location(line: 0, column: 0)
  SequenceInput[Token](tokens: tokens, index: 0, location: location)

proc peek*[Token](input: SequenceInput[Token]): ?!Token =
  mixin endOfInput
  if input.index < input.tokens.len:
    result = success input.tokens[input.index]
  elif input.index == input.tokens.len:
    result = success Token.endOfInput
  else:
    result = failure "reading beyond end of input: " & $input.location

proc read*[Token](input: SequenceInput[Token]): ?!Token =
  result = input.peek()
  if result.isSuccess:
    if input.index < input.tokens.len:
      inc input.location.column
    inc input.index

func ended*[Token](input: SequenceInput[Token]): bool =
  input.index >= input.tokens.len

type
  StringInput = ref object of Input[char]
    characters: string
    index: int

func new*(_: type Input, characters: string): StringInput =
  let location = Location(line: 1, column: 1)
  StringInput(characters: characters, index: 0, location: location)

proc peek*(input: StringInput): ?!char =
  if input.index < input.characters.len:
    let character = input.characters[input.index]
    result = success character
  elif input.index == input.characters.len:
    result = success '\0'
  else:
    result = failure "reading beyond end of input: " & $input.location

proc read*(input: StringInput): ?!char =
  result = input.peek()
  if result.isSuccess:
    if input.index < input.characters.len:
      if !result == '\n':
        inc input.location.line
        input.location.column = 1
      else:
        inc input.location.column
    inc input.index

func ended*(input: StringInput): bool =
  input.index >= input.characters.len

iterator items*(input: Input): auto =
  var failure = false
  while not input.ended() and not failure:
    let item = input.read()
    failure = item.isFailure
    yield item
