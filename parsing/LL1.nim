import ./basics
import ./grammar

func update*(symbol: Symbol)
func update*(conversion: Conversion)
func update*(concatenation: Concatenation)
func update*(optional: Optional)
func update*(rule: Recursion)

func update*(symbol: Symbol) =
  symbol.first.incl(symbol.categories)
  symbol.last.incl(symbol)

func update*(conversion: Conversion) =
  let operand = conversion.operand
  operand.update()
  conversion.canBeEmpty = operand.canBeEmpty
  conversion.first.incl(operand.first)
  for item in operand.last.items:
    conversion.last.incl(item)
  conversion.last.incl(conversion)

func update*(concatenation: Concatenation) =
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

func update*(optional: Optional) =
  let operand = optional.operand
  operand.update()
  optional.canBeEmpty = true
  optional.first.incl(operand.first)
  for item in operand.last.items:
    optional.last.incl(item)
  optional.last.incl(optional)

func update*(rule: Recursion) =
  rule.updateClosure()
