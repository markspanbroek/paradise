import ./basics
import ./grammar
import ./input
import ./characters
import ./tuples
import ./LL1
import ./automaton

proc parse*(automaton: Automaton, symbol: Symbol)
proc parse*(automaton: Automaton, conversion: Conversion)
proc parse*[C: Concatenation](automaton: Automaton, concatenation: C)
proc parse*(automaton: Automaton, optional: Optional)
proc parse*(automaton: Automaton, rule: Recursion)

proc parse*(grammar: Grammar, input: Input): auto =
  var automaton = Automaton.new(input)
  automaton.parse(grammar)
  automaton.run()
  result = grammar.output
  grammar.output.reset()

proc parse*(automaton: Automaton, symbol: Symbol) =
  mixin category
  let input = automaton.input
  let peek = input.peek()
  without token =? peek:
    symbol.output =  peek
  if token.category in symbol.categories:
    symbol.output = input.read()
  else:
    let message = "expected: " & $symbol & " " & $input.location()
    symbol.output = typeof(token).failure message

proc parse*(automaton: Automaton, conversion: Conversion) =
  proc assign() =
    conversion.output = conversion.operand.output.map(conversion.convert)
  automaton.add(assign)
  automaton.parse(conversion.operand)

proc parse*[C: Concatenation](automaton: Automaton, concatenation: C) =
  type Output = typeof(!concatenation.output)
  proc next() =
    without left =? concatenation.left.output, error:
      concatenation.output = Output.failure error
      return
    proc assign() =
      without right =? concatenation.right.output, error:
        concatenation.output = Output.failure error
        return
      when concatenation.left is Concatenation:
        concatenation.output = success left & right
      else:
        concatenation.output = success (left, right)
    automaton.add(assign)
    automaton.parse(concatenation.right)
  automaton.add(next)
  automaton.parse(concatenation.left)

proc parse*(automaton: Automaton, optional: Optional) =
  mixin category
  let operand = optional.operand
  type Output = typeof(!operand.output)
  let input = automaton.input
  without peek =? input.peek(), error:
    optional.output = failure(?Output, error)
    return
  if peek.category notin operand.first:
    optional.output = success none Output
    return
  proc assign() =
    without value =? operand.output, error:
      optional.output = failure(?Output, error)
      return
    optional.output = success some value
  automaton.add(assign)
  automaton.parse(operand)

proc parse*(automaton: Automaton, rule: Recursion) =
  rule.parseClosure(automaton)

type Parser*[G] = object
  grammar: G

func parser*(grammar: Grammar): auto =
  grammar.update()
  Parser[typeof(grammar)](grammar: grammar)

proc parse*(parser: Parser, input: Input): auto =
  parser.grammar.parse(input)

proc parse*[G: Grammar[char]](parser: Parser[G], input: string): auto =
  parser.parse(Input.new(input))

proc parse*[Token; G: Grammar[Token]](parser: Parser[G], input: seq[Token]): auto =
  parser.parse(Input.new(input))

template parse*(grammar: Grammar, input: untyped): auto =
  grammar.parser.parse(input)
