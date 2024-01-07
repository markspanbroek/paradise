import ./grammar

func update*(symbol: Symbol) =
  symbol.first.incl(symbol.categories)

func update*(conversion: Conversion) =
  conversion.operand.update()
  conversion.first.incl(conversion.operand.first)

func update*(concatenation: Concatenation) =
  concatenation.left.update()
  concatenation.right.update()
  concatenation.first.incl(concatenation.left.first)

func update*(optional: Optional) =
  optional.operand.update()
  optional.first.incl(optional.operand.first)
