import ./basics
import ./grammar
import ./input
import ./parser

type Peek[Token] = object
  next: ?!Token
  location: Location
  ended: bool

func tokenize*[In](grammar: Grammar, input: Input[In]): auto =
  type Out = typeof(!grammar.output)
  let output = Input[Out]()
  var peeked: ?Peek[Out]
  output.peek = proc: ?!Out =
    without var peeking =? peeked:
      peeking.location = input.location()
      peeking.ended = input.ended()
      grammar.parse(input)
      peeking.next = grammar.output
      peeked = some peeking
    peeking.next
  output.read = proc: ?!Out =
    if peeking =? peeked:
      result = peeking.next
      peeked = none Peek[Out]
    else:
      grammar.parse(input)
      result = grammar.output
  output.ended = proc: bool =
    if peeking =? peeked:
      peeking.ended
    else:
      input.ended()
  output

func tokenize*(grammar: Grammar, input: string): auto =
  tokenize(grammar, Input.new(input))

func tokenize*[Token](grammar: Grammar, input: seq[Token]): auto =
  tokenize(grammar, Input.new(input))
