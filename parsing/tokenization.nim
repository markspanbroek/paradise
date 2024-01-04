import ./grammar
import ./input
import ./parser

type Tokenization[P, I] = object
  parslet: P
  input: I

func tokenize*[P: Parslet[char]](parslet: P, input: string): auto =
  let input = Input.new(input)
  Tokenization[P, typeof(input)](parslet: parslet, input: input)

func tokenize*[Token; P: Parslet[Token]](parslet: P, input: seq[Token]): auto =
  let input = Input.new(input)
  Tokenization[P, typeof(input)](parslet: parslet, input: input)

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
