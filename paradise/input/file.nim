import ../basics
import ./input
import ./location

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

