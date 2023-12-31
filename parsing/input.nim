import ./basics

type Input* = ref object
  read*: proc: ?!char

func new*(_: type Input, input: string): Input =
  var index = 0
  proc read: ?!char =
    if index < input.len:
      result = success input[index]
      inc index
    elif index == input.len:
      result = success '\0'
      inc index
    else:
      result = failure "reading beyond end of string"

  Input(read: read)
