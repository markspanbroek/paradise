import ./basics
import ./grammar
import ./LL1
import ./automaton
import ./parsing

func define*[Token; G: Grammar[Token]](rule: Recursion, definition: G) =
  var recursive = false
  var latestRound = 0
  rule.updateClosure = proc(round: int, again: var bool) =
    if round > latestRound :
      latestRound = round
      definition.update(round, again)
      if not rule.canBeEmpty and definition.canBeEmpty:
        rule.canBeEmpty = definition.canBeEmpty
        again = again or recursive
      if not (definition.first <= rule.first):
        rule.first.incl(definition.first)
        again = again or recursive
      if not (definition.last <= rule.last):
        rule.last.incl(definition.last)
        again = again or recursive
      rule.last.incl(rule)
    else:
      recursive = true
  rule.parseClosure = proc(automaton: Automaton[Token]) =
    bind basics.unsafeError
    proc assign() =
      rule.output = definition.output
    automaton.add(assign)
    automaton.parse(definition)
