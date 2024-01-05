import ./basics
import ./grammar
import ./input
import ./parser

type Tokenization[Token, ParsletType, InputType] = ref object of Input[Token]
  parslet: ParsletType
  input: InputType

func tokenize*(parslet: Parslet, input: Input): auto =
  type Token = typeof(!parslet.parse(input))
  type ParsletType = typeof(parslet)
  type InputType = typeof(input)
  Tokenization[Token, ParsletType, InputType](parslet: parslet, input: input)

func tokenize*(parslet: Parslet, input: string): auto =
  tokenize(parslet, Input.new(input))

func tokenize*[Token](parslet: Parslet, input: seq[Token]): auto =
  tokenize(parslet, Input.new(input))

func read*(tokenization: Tokenization): auto =
  let parslet = tokenization.parslet
  let input = tokenization.input
  parslet.parse(input)

func location*(tokenization: Tokenization): string =
  tokenization.input.location

func ended*(tokenization: Tokenization): bool =
  tokenization.input.ended

iterator items*(tokenization: Tokenization): auto =
  let input = tokenization.input
  let parslet = tokenization.parslet
  var failure = false
  while not input.ended() and not failure:
    let parsed = parslet.parse(input)
    failure = parsed.isFailure
    yield parsed
