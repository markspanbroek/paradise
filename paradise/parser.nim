import ./grammar
import ./parsing
import ./input
import ./LL1

type Parser*[G] = object
  grammar: G

func parser*[Token; G: Grammar[Token]](grammar: G): auto =
  grammar.update()
  Parser[typeof(grammar)](grammar: grammar)

proc parse*[Token; G: Grammar[Token]](parser: Parser[G], input: Input): auto =
  parser.grammar.parse(input)

proc parse*[G: Grammar[char]](parser: Parser[G], input: string): auto =
  parser.parse(Input.new(input))

proc parse*[Token; G: Grammar[Token]](parser: Parser[G], input: seq[Token]): auto =
  parser.parse(Input.new(input))

proc parse*[G: Grammar[char]](parser: Parser[G], input: File): auto =
  parser.parse(Input.new(input))

template parse*[Token; G: Grammar[Token]](grammar: G, input: untyped): auto =
  grammar.parser.parse(input)
