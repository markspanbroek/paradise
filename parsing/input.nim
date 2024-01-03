import ./basics
import ./characters
import ./location

export location.`$`

type Input*[Token, Location] = ref object
  read*: proc: ?!Token
  location*: Location
  atEnd*: bool

func new[Token](_: type Input, Location: type, tokens: seq[Token]): auto =
  mixin endOfInput
  var input = Input[Token, Location](location: Location.init())
  var index = 0
  input.read = proc: ?!Token =
    if index < tokens.len:
      input.location.update(tokens[index])
      result = success tokens[index]
      inc index
    elif index == tokens.len:
      result = success Token.endOfInput
      inc index
    else:
      result = failure "reading beyond end of input " & $input.location
    if index >= tokens.len:
      input.atEnd = true
  input

func new*[Token](_: type Input, input: seq[Token]): auto =
  Input.new(SequenceLocation, input)

func new*(_: type Input, input: string): auto =
  Input.new(TextLocation, cast[seq[char]](input))
