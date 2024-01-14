import ./basics
import ./grammar
import ./input
import ./LL1
import ./parsing

func define*[Token, Category; P: Parslet[Token, Category]](rule: Recursion, definition: P) =
  var updating = false
  rule.updateClosure = proc =
    if not updating:
      updating = true
      definition.update()
      rule.canBeEmpty = definition.canBeEmpty
      rule.first.incl(definition.first)
      updating = false
  rule.runClosure = proc(input: Input[Token]) =
    bind basics.error
    rule.output = definition.parse(input)
