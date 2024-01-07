import ./grammar

func update*[Token, Category](symbol: Symbol[Token, Category]) =
  symbol.first.incl(symbol.categories)

func update*[Token, Category, Operand, From, To](conversion: Conversion[Token, Category, Operand, From, To]) =
  conversion.operand.update()
  conversion.first.incl(conversion.operand.first)

func update*[Token, Category, Left, Right](concatenation: Concatenation[Token, Category, Left, Right]) =
  concatenation.left.update()
  concatenation.right.update()
  concatenation.first.incl(concatenation.left.first)

func update*(optional: Optional) =
  optional.operand.update()
  optional.first.incl(optional.operand.first)
