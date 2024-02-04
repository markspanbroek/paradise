import ./basics
import ./grammar
import ./input
import ./characters
import ./tuples
import ./LL1
import ./automaton



proc step*[Token](symbol: Symbol, automaton: var Automaton[Token]): Step[Token]
proc step*[Token](conversion: Conversion, automaton: var Automaton[Token]): Step[Token]
proc step*[Token; C: Concatenation](concatenation: C, automaton: var Automaton[Token]): Step[Token]
proc step*[Token](optional: Optional, automaton: var Automaton[Token]): Step[Token]
proc step*[Token](rule: Recursion, automaton: var Automaton[Token]): Step[Token]

proc parse*(grammar: Grammar, input: Input): auto =
  var automaton = Automaton.init(input)
  automaton.todo.add(grammar.step(automaton))
  automaton.run()
  result = grammar.output
  grammar.output.reset()

proc step*[Token](symbol: Symbol, automaton: var Automaton[Token]): Step[Token] =
  mixin category
  proc(automaton: var Automaton[Token]) =
    let input = automaton.input
    let peek = input.peek()
    without token =? peek:
      symbol.output =  peek
    if token.category in symbol.categories:
      symbol.output = input.read()
    else:
      let message = "expected: " & $symbol & " " & $input.location()
      symbol.output = typeof(token).failure message

proc step*[Token](conversion: Conversion, automaton: var Automaton[Token]): Step[Token] =
  proc convert(automaton: var Automaton[Token]) =
    conversion.output = conversion.operand.output.map(conversion.convert)
  proc(automaton: var Automaton[Token]) =
    automaton.todo.add(convert)
    automaton.todo.add(conversion.operand.step(automaton))

proc step*[Token; C: Concatenation](concatenation: C, automaton: var Automaton[Token]): Step[Token] =
  type Output = typeof(!concatenation.output)
  proc between(automaton: var Automaton[Token]) =
    without left =? concatenation.left.output, error:
      concatenation.output = Output.failure error
      return
    proc after(automaton: var Automaton[Token]) =
      without right =? concatenation.right.output, error:
        concatenation.output = Output.failure error
        return
      when concatenation.left is Concatenation:
        concatenation.output = success left & right
      else:
        concatenation.output = success (left, right)
    automaton.todo.add(after)
    automaton.todo.add(concatenation.right.step(automaton))
  proc(automaton: var Automaton[Token]) =
    automaton.todo.add(between)
    automaton.todo.add(concatenation.left.step(automaton))

proc step*[Token](optional: Optional, automaton: var Automaton[Token]): Step[Token] =
  mixin category
  let operand = optional.operand
  type Output = typeof(!operand.output)
  proc(automaton: var Automaton[Token]) =
    let input = automaton.input
    without peek =? input.peek(), error:
      optional.output = failure(?Output, error)
      return
    if peek.category notin operand.first:
      optional.output = success none Output
      return
    proc after(automaton: var Automaton[Token]) =
      without value =? operand.output, error:
        optional.output = failure(?Output, error)
        return
      optional.output = success some value
    automaton.todo.add(after)
    automaton.todo.add(operand.step(automaton))

proc step*[Token](rule: Recursion, automaton: var Automaton[Token]): Step[Token] =
  rule.stepClosure(automaton)

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
