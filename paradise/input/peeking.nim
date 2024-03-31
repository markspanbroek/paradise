import ../basics
import ./input
import ./location

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

