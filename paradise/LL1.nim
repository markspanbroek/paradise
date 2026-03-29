import ./basics
import ./grammar
import ./parsing
import ./automaton

func update*(symbol: Symbol, round: int, again: var bool)
func update*(conversion: AnyConversion, round: int, again: var bool)
func update*(concatenation: Concatenation, round: int, again: var bool)
func update*(optional: Optional, round: int, again: var bool)
func update*(repetition: RepetitionStar, round: int, again: var bool)
func update*(repetition: RepetitionPlus, round: int, again: var bool)
func update*(rule: Recursion, round: int, again: var bool)
func update*(alternatives: Alternatives, round: int, again: var bool)

func update*[Token; G: Grammar[Token]](grammar: G) =
  var round = 1
  var again = false
  grammar.update(round, again)
  while again:
    again = false
    inc round
    grammar.update(round, again)

func update*(symbol: Symbol, round: int, again: var bool) =
  bind grammar.hash
  symbol.first.incl(symbol.categories)
  symbol.last.incl(symbol)

func update*(conversion: AnyConversion, round: int, again: var bool) =
  bind basics.items
  let operand = conversion.operand
  operand.update(round, again)
  conversion.canBeEmpty = operand.canBeEmpty
  conversion.first.incl(operand.first)
  conversion.last.incl(operand.last)
  conversion.last.incl(conversion)

func update*(concatenation: Concatenation, round: int, again: var bool) =
  let left = concatenation.left
  let right = concatenation.right
  left.update(round, again)
  right.update(round, again)
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

func update*(optional: Optional, round: int, again: var bool) =
  bind basics.items
  let operand = optional.operand
  operand.update(round, again)
  optional.canBeEmpty = true
  optional.first.incl(operand.first)
  optional.last.incl(operand.last)
  optional.last.incl(optional)

func update*(repetition: RepetitionStar, round: int, again: var bool) =
  let operand = repetition.operand
  operand.update(round, again)
  repetition.canBeEmpty = true
  repetition.first.incl(operand.first)
  repetition.last.incl(operand.last)
  repetition.last.incl(repetition)
  for last in operand.last.items:
    for first in operand.first:
      last.follow.incl(first)

func update*(repetition: RepetitionPlus, round: int, again: var bool) =
  let operand = repetition.operand
  operand.update(round, again)
  repetition.canBeEmpty = operand.canBeEmpty
  repetition.first.incl(operand.first)
  repetition.last.incl(operand.last)
  repetition.last.incl(repetition)
  for last in operand.last.items:
    for first in operand.first:
      last.follow.incl(first)

func update*(rule: Recursion, round: int, again: var bool) =
  rule.updateClosure(round, again)

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
    if alternatives.parseClosures[category.int] == nil:
      alternatives.parseClosures[category.int] = parseChoice

func update*(alternatives: Alternatives, round: int, again: var bool) =
  for choice in alternatives.choices.fields:
    choice.update(round, again)
    alternatives.canBeEmpty = alternatives.canBeEmpty or choice.canBeEmpty
    alternatives.first.incl(choice.first)
    alternatives.last.incl(choice.last)
    alternatives.updateClosures(choice)
  alternatives.last.incl(alternatives)
