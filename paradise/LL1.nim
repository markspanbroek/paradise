import ./basics
import ./grammar
import ./parsing
import ./automaton

func update*(symbol: Symbol, again: var bool)
func update*(conversion: AnyConversion, again: var bool)
func update*(concatenation: Concatenation, again: var bool)
func update*(optional: Optional, again: var bool)
func update*(repetition: RepetitionStar, again: var bool)
func update*(repetition: RepetitionPlus, again: var bool)
func update*(rule: Recursion, again: var bool)
func update*(alternatives: Alternatives, again: var bool)

func update*(grammar: Grammar) =
  var again = false
  grammar.update(again)
  while again:
    again = false
    grammar.update(again)

func update*(symbol: Symbol, again: var bool) =
  bind grammar.hash
  symbol.first.incl(symbol.categories)
  symbol.last.incl(symbol)

func update*(conversion: AnyConversion, again: var bool) =
  bind basics.items
  let operand = conversion.operand
  operand.update()
  conversion.canBeEmpty = operand.canBeEmpty
  conversion.first.incl(operand.first)
  conversion.last.incl(operand.last)
  conversion.last.incl(conversion)

func update*(concatenation: Concatenation, again: var bool) =
  let left = concatenation.left
  let right = concatenation.right
  left.update()
  right.update()
  concatenation.canBeEmpty = left.canBeEmpty and right.canBeEmpty
  concatenation.first.incl(left.first)
  concatenation.last.incl(right.last)
  if left.canBeEmpty:
    concatenation.first.incl(right.first)
  if right.canBeEmpty:
    concatenation.last.incl(left.last)
  concatenation.last.incl(concatenation)
  for last in left.last.items:
    for first in right.first:
      last.follow.incl(first)

func update*(optional: Optional, again: var bool) =
  bind basics.items
  let operand = optional.operand
  operand.update()
  optional.canBeEmpty = true
  optional.first.incl(operand.first)
  optional.last.incl(operand.last)
  optional.last.incl(optional)

func update*(repetition: RepetitionStar, again: var bool) =
  let operand = repetition.operand
  operand.update()
  repetition.canBeEmpty = true
  repetition.first.incl(operand.first)
  repetition.last.incl(operand.last)
  repetition.last.incl(repetition)
  for last in operand.last.items:
    for first in operand.first:
      last.follow.incl(first)

func update*(repetition: RepetitionPlus, again: var bool) =
  let operand = repetition.operand
  operand.update()
  repetition.canBeEmpty = operand.canBeEmpty
  repetition.first.incl(operand.first)
  repetition.last.incl(operand.last)
  repetition.last.incl(repetition)
  for last in operand.last.items:
    for first in operand.first:
      last.follow.incl(first)

func update*(rule: Recursion, again: var bool) =
  rule.updateClosure(again)

func updateClosures[Choice](alternatives: Alternatives, choice: Choice) =
  bind basics.unsafeError
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
    alternatives.canBeEmpty = alternatives.canBeEmpty or choice.canBeEmpty
    alternatives.first.incl(choice.first)
    alternatives.last.incl(choice.last)
    alternatives.updateClosures(choice)
  alternatives.last.incl(alternatives)
