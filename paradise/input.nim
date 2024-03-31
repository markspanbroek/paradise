import ./basics
import ./characters

type
  Input*[Token] = ref object of RootObj
    peek*: proc: ?!Token
    read*: proc: ?!Token
    ended*: proc: bool
    location*: proc: Location
  Location* = object
    line*: int
    column*: int

func `$`*(location: Location): string =
  "(" & $location.line & ", " & $location.column & ")"

func new*[Token](
  _: type Input,
  read: proc: ?!Token,
  peek: proc: ?!Token,
  ended: proc: bool,
  location: proc: Location
): Input[Token] =
  Input[Token](read: read, peek: peek, ended: ended, location: location)

type Peek[Token] = object
  next: ?!Token
  location: Location
  ended: bool

func new*[Token](
  _: type Input,
  read: proc: ?!Token,
  ended: proc: bool,
  location: proc: Location
): Input[Token] =
  var peeked: ?Peek[Token]
  proc peek: ?!Token =
    without var peeking =? peeked:
      peeking.location = location()
      peeking.ended = ended()
      peeking.next = read()
      peeked = some peeking
    peeking.next
  proc peekingRead: ?!Token =
    if peeking =? peeked:
      result = peeking.next
      peeked = none Peek[Token]
    else:
      result = read()
  proc peekingEnded: bool =
    if peeking =? peeked:
      peeking.ended
    else:
      ended()
  proc peekingLocation: Location =
    if peeking =? peeked:
      peeking.location
    else:
      location()
  Input.new(
    peek = peek,
    read = peekingRead,
    ended = peekingEnded,
    location = peekingLocation
  )

func new*[Token](_: type Input, tokens: seq[Token]): Input[Token] =
  mixin endOfInput
  var index = 0
  var loc = Location(line: 0, column: 0)
  proc peek: ?!Token =
    if index < tokens.len:
      success tokens[index]
    elif index == tokens.len:
      success Token.endOfInput
    else:
      failure "reading beyond end of input: " & $loc
  proc read: ?!Token =
    result = peek()
    if result.isSuccess:
      if index < tokens.len:
        inc loc.column
      inc index
  proc ended: bool =
    index >= tokens.len
  proc location: Location =
    loc
  Input.new(peek = peek, read = read, ended = ended, location = location)

func new*(_: type Input, characters: string): Input[char] =
  var index = 0
  var loc = Location(line: 1, column: 1)
  proc peek: ?!char =
    if index < characters.len:
      success characters[index]
    elif index == characters.len:
      success '\0'
    else:
      failure "reading beyond end of input: " & $loc
  proc read: ?!char =
    result = peek()
    if result.isSuccess:
      if index < characters.len:
        if !result == '\n':
          inc loc.line
          loc.column = 1
        else:
          inc loc.column
      inc index
  proc ended: bool =
    index >= characters.len
  proc location: Location =
    loc
  Input.new(peek = peek, read = read, ended = ended, location = location)

func new*(_: type Input, file: File, bufferSize: static int = 2048): Input[char] =
  var buffer: array[bufferSize, char]
  var length = 0
  var index = 0
  var finished = false
  var loc = Location(line: 1, column: 1)
  proc peek: ?!char =
    if index < length:
      success buffer[index]
    elif finished:
      failure "reading beyond end of input: " & $loc
    elif endOfFile(file):
      success '\0'
    else:
      try:
        length = readChars(file, buffer)
        index = 0
        peek()
      except IOError as error:
        failure error.msg & " " & $loc
  proc ended: bool =
    index >= length and endOfFile(file)
  proc read: ?!char =
    result = peek()
    if result.isSuccess:
      if not ended():
        if !result == '\n':
          inc loc.line
          loc.column = 1
        else:
          inc loc.column
        inc index
      else:
        finished = true
  proc location: Location =
    loc
  Input.new(peek = peek, read = read, ended = ended, location = location)

iterator items*(input: Input): auto =
  var failure = false
  while not input.ended() and not failure:
    let item = input.read()
    failure = item.isFailure
    yield item
