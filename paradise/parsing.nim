import ./basics
import ./grammar
import ./input
import ./characters
import ./tuples
import ./automaton

proc parse*(automaton: Automaton, symbol: Symbol)
proc parse*(automaton: Automaton, conversion: Conversion)
proc parse*[C: Concatenation](automaton: Automaton, concatenation: C)
proc parse*(automaton: Automaton, optional: Optional)
proc parse*(automaton: Automaton, repetition: RepetitionStar)
proc parse*(automaton: Automaton, repetition: RepetitionPlus)
proc parse*(automaton: Automaton, rule: Recursion)
proc parse*(automaton: Automaton, alternatives: Alternatives)

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
    symbol.output = peek
    return
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
        concatenation.output = success left && right
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

proc parse*(automaton: Automaton, repetition: RepetitionStar) =
  mixin category
  type Output = typeof(!repetition.output)
  let operand = repetition.operand
  let input = automaton.input
  var output: Output
  proc next()
  proc append() =
    without value =? operand.output, error:
      repetition.output = failure(Output, error)
      return
    output.add(value)
    next()
  proc next() =
    without peek =? input.peek(), error:
      repetition.output = failure(Output, error)
      return
    if peek.category notin operand.first:
      repetition.output = success output
      return
    automaton.add(append)
    automaton.parse(operand)
  next()

proc parse*(automaton: Automaton, repetition: RepetitionPlus) =
  mixin category
  type Output = typeof(!repetition.output)
  let operand = repetition.operand
  let input = automaton.input
  var output: Output
  proc next()
  proc append() =
    without value =? operand.output, error:
      repetition.output = failure(Output, error)
      return
    output.add(value)
    next()
  proc next() =
    without peek =? input.peek(), error:
      repetition.output = failure(Output, error)
      return
    if peek.category notin operand.first:
      repetition.output = success output
      return
    automaton.add(append)
    automaton.parse(operand)
  automaton.add(append)
  automaton.parse(operand)

proc parse*(automaton: Automaton, rule: Recursion) =
  rule.parseClosure(automaton)

proc parse*(automaton: Automaton, alternatives: Alternatives) =
  mixin category
  type Output = typeof(!alternatives.output)
  let input = automaton.input
  without peek =? input.peek(), error:
    alternatives.output = failure(Output, error)
    return
  without closure =? alternatives.parseClosures[peek.category.int]:
    let message = "expected: " & $alternatives & " " & $input.location()
    alternatives.output = Output.failure message
    return
  closure(automaton)
