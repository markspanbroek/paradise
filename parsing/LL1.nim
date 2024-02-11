import ./basics
import ./grammar
import ./parsing
import ./automaton

func update*(symbol: Symbol, again: var bool)
func update*(conversion: Conversion, again: var bool)
func update*(concatenation: Concatenation, again: var bool)
func update*(optional: Optional, again: var bool)
func update*(rule: Recursion, again: var bool)
func update*(alternatives: Alternatives, again: var bool)

func update*(grammar: Grammar) =
  var again = false
  grammar.update(again)
  while again:
    again = false
    grammar.update(again)

func update*(symbol: Symbol, again: var bool) =
  symbol.first.incl(symbol.categories)
  symbol.last.incl(symbol)

func update*(conversion: Conversion, again: var bool) =
  let operand = conversion.operand
  operand.update()
  conversion.canBeEmpty = operand.canBeEmpty
  conversion.first.incl(operand.first)
  for item in operand.last.items:
    conversion.last.incl(item)
  conversion.last.incl(conversion)

func update*(concatenation: Concatenation, again: var bool) =
  let left = concatenation.left
  let right = concatenation.right
  left.update()
  right.update()
  concatenation.canBeEmpty = left.canBeEmpty and right.canBeEmpty
  concatenation.first.incl(left.first)
  for item in right.last.items:
    concatenation.last.incl(item)
  if left.canBeEmpty:
    concatenation.first.incl(right.first)
  if right.canBeEmpty:
    for item in left.last.items:
      concatenation.last.incl(item)
  concatenation.last.incl(concatenation)
  for last in left.last.items:
    for first in right.first:
      last.follow.incl(first)

func update*(optional: Optional, again: var bool) =
  let operand = optional.operand
  operand.update()
  optional.canBeEmpty = true
  optional.first.incl(operand.first)
  for item in operand.last.items:
    optional.last.incl(item)
  optional.last.incl(optional)

func update*(rule: Recursion, again: var bool) =
  rule.updateClosure(again)

func updateClosures[Choice](alternatives: Alternatives, choice: Choice) =
  bind basics.error
  proc assign() =
    alternatives.output = choice.output
  proc parseChoice(automaton: Automaton[Alternatives.Token]) =
    automaton.add(assign)
    automaton.parse(choice)
  var categories = choice.first
  if choice.canBeEmpty:
    categories.incl(choice.follow)
  for category in categories:
    alternatives.parseClosures[category.int] = parseChoice

func update*(alternatives: Alternatives, again: var bool) =
  for choice in alternatives.choices.fields:
    choice.update()
    if choice.canBeEmpty:
      alternatives.canBeEmpty = true
    for item in choice.first.items:
      alternatives.first.incl(item)
    for item in choice.last.items:
      alternatives.last.incl(item)
    alternatives.updateClosures(choice)
  alternatives.last.incl(alternatives)
