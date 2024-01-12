import ./basics
import ./grammar
import ./input
import ./parser

type
  Tokenization[Token, Location, GrammarType, InputType] = ref object of Input[Token]
    grammar: GrammarType
    input: InputType
    peeking: ?Peeking[Token, Location]
  Peeking[Token, Location] = object
    next: ?!Token
    location: Location
    ended: bool

func tokenize*(grammar: Grammar, input: Input): auto =
  type Token = typeof(!grammar.parse(input))
  type GrammarType = typeof(grammar)
  type InputType = typeof(input)
  type Location = typeof(input.location)
  Tokenization[Token, Location, GrammarType, InputType](grammar: grammar, input: input)

func tokenize*(grammar: Grammar, input: string): auto =
  tokenize(grammar, Input.new(input))

func tokenize*[Token](grammar: Grammar, input: seq[Token]): auto =
  tokenize(grammar, Input.new(input))

func peek*(tokenization: Tokenization): auto =
  without var peeking =? tokenization.peeking:
    let grammar = tokenization.grammar
    let input = tokenization.input
    peeking.location = input.location
    peeking.ended = input.ended
    peeking.next = grammar.parse(input)
    tokenization.peeking = some peeking
  peeking.next

func read*(tokenization: Tokenization): auto =
  if peeking =? tokenization.peeking:
    result = peeking.next
    tokenization.peeking.reset()
  else:
    let grammar = tokenization.grammar
    let input = tokenization.input
    result = grammar.parse(input)

func location*(tokenization: Tokenization): auto =
  if peeking =? tokenization.peeking:
    peeking.location
  else:
    tokenization.input.location

func ended*(tokenization: Tokenization): bool =
  if peeking =? tokenization.peeking:
    peeking.ended
  else:
    tokenization.input.ended
