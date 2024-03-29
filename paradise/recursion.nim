import ./basics
import ./grammar
import ./LL1
import ./automaton
import ./parsing

func define*[Token; G: Grammar[Token]](rule: Recursion, definition: G) =
  var updating = false
  rule.updateClosure = proc(again: var bool) =
    if not updating:
      updating = true
      definition.update()
      if not rule.canBeEmpty and definition.canBeEmpty:
        rule.canBeEmpty = definition.canBeEmpty
        again = true
      if not (definition.first <= rule.first):
        rule.first.incl(definition.first)
        again = true
      if not (definition.last <= rule.last):
        rule.last.incl(definition.last)
        again = true
      rule.last.incl(rule)
      updating = false
  rule.parseClosure = proc(automaton: Automaton[Token]) =
    bind basics.unsafeError
    proc assign() =
      rule.output = definition.output
    automaton.add(assign)
    automaton.parse(definition)
