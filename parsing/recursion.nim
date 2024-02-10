import ./basics
import ./grammar
import ./LL1
import ./automaton
import ./parser

func define*[Token, Category; P: Parslet[Token, Category]](rule: Recursion, definition: P) =
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
        for item in definition.last.items:
          rule.last.incl(item)
        again = true
      rule.last.incl(rule)
      updating = false
  rule.parseClosure = proc(automaton: Automaton[Token]) =
    bind basics.error
    proc assign() =
      rule.output = definition.output
    automaton.add(assign)
    automaton.parse(definition)
