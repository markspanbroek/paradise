import ../basics
import ./location

type
  Input*[Token] = ref object of RootObj
    peek*: proc: ?!Token
    read*: proc: ?!Token
    ended*: proc: bool
    location*: proc: Location

func new*[Token](
  _: type Input,
  read: proc: ?!Token,
  peek: proc: ?!Token,
  ended: proc: bool,
  location: proc: Location
): Input[Token] =
  Input[Token](read: read, peek: peek, ended: ended, location: location)

iterator items*(input: Input): auto =
  var failure = false
  while not input.ended() and not failure:
    let item = input.read()
    failure = item.isFailure
    yield item
