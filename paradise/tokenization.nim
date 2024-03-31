import ./basics
import ./grammar
import ./input
import ./parser

func tokenize*[In](parser: Parser, input: Input[In]): auto =
  type Out = typeof(!parser.parse(input))
  proc read: ?!Out =
    parser.parse(input)
  Input.new(read = read, ended = input.ended, location = input.location)

func tokenize*(parser: Parser, input: string): auto =
  tokenize(parser, Input.new(input))

func tokenize*[Token; G: Grammar[Token]](parser: Parser[G], input: seq[Token]): auto =
  tokenize(parser, Input.new(input))

template tokenize*(grammar: Grammar, input: untyped): auto =
  grammar.parser.tokenize(input)
