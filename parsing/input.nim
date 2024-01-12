import ./basics
import ./characters

type
  Input*[Token] = ref object of RootObj
    peek*: proc: ?!Token
    read*: proc: ?!Token
    ended*: proc: bool
    location*: proc: Location
  Location* = object
    line: int
    column: int

func `$`*(location: Location): string =
  "(" & $location.line & ", " & $location.column & ")"

func new*[Token](_: type Input, tokens: seq[Token]): Input[Token] =
  mixin endOfInput
  let input = Input[Token]()
  var index = 0
  var location = Location(line: 0, column: 0)
  input.peek = proc: ?!Token =
    if index < tokens.len:
      success tokens[index]
    elif index == tokens.len:
      success Token.endOfInput
    else:
      failure "reading beyond end of input: " & $location
  input.read = proc: ?!Token =
    result = input.peek()
    if result.isSuccess:
      if index < tokens.len:
        inc location.column
      inc index
  input.ended = proc: bool =
    index >= tokens.len
  input.location = proc: Location =
    location
  input

func new*(_: type Input, characters: string): Input[char] =
  let input = Input[char]()
  var index = 0
  var location = Location(line: 1, column: 1)
  input.peek = proc: ?!char =
    if index < characters.len:
      success characters[index]
    elif index == characters.len:
      success '\0'
    else:
      failure "reading beyond end of input: " & $location
  input.read = proc: ?!char =
    result = input.peek()
    if result.isSuccess:
      if index < characters.len:
        if !result == '\n':
          inc location.line
          location.column = 1
        else:
          inc location.column
      inc index
  input.ended = proc: bool =
    index >= characters.len
  input.location = proc: Location =
    location
  input

iterator items*(input: Input): auto =
  var failure = false
  while not input.ended() and not failure:
    let item = input.read()
    failure = item.isFailure
    yield item
