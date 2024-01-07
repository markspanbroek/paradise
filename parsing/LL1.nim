import ./grammar

func update*(symbol: Symbol) =
  symbol.first.incl(symbol.categories)

func update*(conversion: Conversion) =
  let operand = conversion.operand
  operand.update()
  conversion.canBeEmpty = operand.canBeEmpty
  conversion.first.incl(operand.first)

func update*(concatenation: Concatenation) =
  let left = concatenation.left
  let right = concatenation.right
  left.update()
  right.update()
  concatenation.canBeEmpty = left.canBeEmpty and right.canBeEmpty
  concatenation.first.incl(left.first)
  if left.canBeEmpty:
    concatenation.first.incl(right.first)

func update*(optional: Optional) =
  let operand = optional.operand
  operand.update()
  optional.canBeEmpty = true
  optional.first.incl(operand.first)
