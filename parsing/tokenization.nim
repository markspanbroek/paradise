import ./basics
import ./grammar
import ./input
import ./parser

type Peek[Token] = object
  next: ?!Token
  location: Location
  ended: bool

func tokenize*[In](parser: Parser, input: Input[In]): auto =
  type Out = typeof(!parser.parse(input))
  let output = Input[Out]()
  var peeked: ?Peek[Out]
  output.peek = proc: ?!Out =
    without var peeking =? peeked:
      peeking.location = input.location()
      peeking.ended = input.ended()
      peeking.next = parser.parse(input)
      peeked = some peeking
    peeking.next
  output.read = proc: ?!Out =
    if peeking =? peeked:
      result = peeking.next
      peeked = none Peek[Out]
    else:
      result = parser.parse(input)
  output.ended = proc: bool =
    if peeking =? peeked:
      peeking.ended
    else:
      input.ended()
  output

func tokenize*(parser: Parser, input: string): auto =
  tokenize(parser, Input.new(input))

func tokenize*[Token; G: Grammar[Token]](parser: Parser[G], input: seq[Token]): auto =
  tokenize(parser, Input.new(input))

template tokenize*(grammar: Grammar, input: untyped): auto =
  grammar.parser.tokenize(input)
