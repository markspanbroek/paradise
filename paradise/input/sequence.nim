import ../basics
import ./input
import ./location

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

