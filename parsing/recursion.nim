import ./basics
import ./grammar
import ./LL1
import ./automaton
import ./parser

func define*[Token, Category; P: Parslet[Token, Category]](rule: Recursion, definition: P) =
  var updating = false
  rule.updateClosure = proc =
    if not updating:
      updating = true
      definition.update()
      rule.canBeEmpty = definition.canBeEmpty
      rule.first.incl(definition.first)
      for item in definition.last.items:
        rule.last.incl(item)
      rule.last.incl(rule)
      updating = false
  rule.parseClosure = proc(automaton: Automaton[Token]) =
    bind basics.error
    proc assign() =
      rule.output = definition.output
    automaton.add(assign)
    automaton.parse(definition)
