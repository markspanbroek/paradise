import ./basics
import ./grammar
import ./input
import ./LL1
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
  rule.parseClosure = proc(input: Input[Token]) =
    bind basics.error
    definition.run(input)
    rule.output = definition.output
