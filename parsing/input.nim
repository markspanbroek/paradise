import ./basics
import ./characters
import ./location

type Input*[Token] = ref object
  read*: proc: ?!Token

func new[Token](_: type Input, Location: type, input: seq[Token]): Input[Token] =
  mixin endOfInput
  var index = 0
  var location = Location.init()
  proc read: ?!Token =
    if index < input.len:
      location.update(input[index])
      result = success input[index]
      inc index
    elif index == input.len:
      result = success Token.endOfInput
      inc index
    else:
      result = failure "reading beyond end of input " & $location
  Input[Token](read: read)

func new*[Token](_: type Input, input: seq[Token]): Input[Token] =
  Input.new(SequenceLocation, input)

func new*(_: type Input, input: string): Input[char] =
  Input.new(TextLocation, cast[seq[char]](input))
