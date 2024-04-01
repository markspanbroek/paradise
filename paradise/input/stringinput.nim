import ../basics
import ./input
import ./location

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
    index > characters.len
  proc location: Location =
    loc
  Input.new(peek = peek, read = read, ended = ended, location = location)
