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
      updating = false
  rule.stepClosure = proc(automaton: var Automaton[Token]): Step[Token] =
    bind basics.error
    proc(automaton: var Automaton[Token]) =
      proc after(automaton: var Automaton[Token]) =
        rule.output = definition.output
      automaton.todo.add(after)
      automaton.todo.add(definition.step(automaton))
