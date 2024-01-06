import ./basics
import ./grammar
import ./input
import ./parser

type
  Tokenization[Token, ParsletType, InputType] = ref object of Input[Token]
    parslet: ParsletType
    input: InputType
    peeking: ?Peeking[Token]
  Peeking[Token] = object
    next: ?!Token
    location: string
    ended: bool

func tokenize*(parslet: Parslet, input: Input): auto =
  type Token = typeof(!parslet.parse(input))
  type ParsletType = typeof(parslet)
  type InputType = typeof(input)
  Tokenization[Token, ParsletType, InputType](parslet: parslet, input: input)

func tokenize*(parslet: Parslet, input: string): auto =
  tokenize(parslet, Input.new(input))

func tokenize*[Token](parslet: Parslet, input: seq[Token]): auto =
  tokenize(parslet, Input.new(input))

func peek*(tokenization: Tokenization): auto =
  without var peeking =? tokenization.peeking:
    let parslet = tokenization.parslet
    let input = tokenization.input
    peeking.location = input.location
    peeking.ended = input.ended
    peeking.next = parslet.parse(input)
    tokenization.peeking = some peeking
  peeking.next

func read*(tokenization: Tokenization): auto =
  if peeking =? tokenization.peeking:
    result = peeking.next
    tokenization.peeking.reset()
  else:
    let parslet = tokenization.parslet
    let input = tokenization.input
    result = parslet.parse(input)

func location*(tokenization: Tokenization): string =
  if peeking =? tokenization.peeking:
    peeking.location
  else:
    tokenization.input.location

func ended*(tokenization: Tokenization): bool =
  if peeking =? tokenization.peeking:
    peeking.ended
  else:
    tokenization.input.ended
