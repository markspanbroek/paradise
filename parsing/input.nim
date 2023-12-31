import ./basics
import ./characters

type Input*[Token] = ref object
  read*: proc: ?!Token

func new*[Token](_: type Input, input: seq[Token]): Input[Token] =
  mixin endOfInput
  var index = 0
  proc read: ?!Token =
    if index < input.len:
      result = success input[index]
      inc index
    elif index == input.len:
      result = success Token.endOfInput
      inc index
    else:
      result = failure "reading beyond end of input"
  Input[Token](read: read)

func new*(_: type Input, input: string): Input[char] =
  Input.new(cast[seq[char]](input))
