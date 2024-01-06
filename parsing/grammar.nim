import ./characters

type Parslet*[Token] = ref object of RootObj

type Symbol*[Token, Category] = ref object of Parslet[Token]
  categories*: set[Category]
  description*: string

func `$`*(symbol: Symbol): string =
  symbol.description

func symbol*[Category](Token: type, categories: set[Category]): auto =
  Symbol[Token, Category](categories: categories, description: $categories)

func symbol*[Category](Token: type, category: Category): auto =
  Symbol[Token, Category](categories: {category}, description: $category)

func symbol*(Token: type, category: char): auto =
  Symbol[Token, char](categories: {category}, description: "'" & category & "'")

func symbol*(characters: char | set[char]): auto =
  symbol(char, characters)

func finish*(Token: type = char): auto =
  mixin category, endOfInput
  symbol(Token, Token.endOfInput.category)

type
  Conversion*[Token, Operand, From, To] = ref object of Parslet[Token]
    operand*: Operand
    convert*: Converter[From, To]
  Converter[From, To] = proc(input: From): To {.noSideEffect.}

func `$`*(conversion: Conversion): string =
  $conversion.operand

func convert*[Token; Operand: Parslet[Token], From, To](operand: Operand, convert: Converter[From, To]): auto =
  Conversion[Token, Operand, From, To](operand: operand, convert: convert)

type Concatenation*[Token, Left, Right] = ref object of Parslet[Token]
  left*: Left
  right*: Right

func `$`*(concatenation: Concatenation): string =
  "(" & $concatenation.left & " & " & $concatenation.right & ")"

func `&`*[Token; Left, Right: Parslet[Token]](left: Left, right: Right): auto =
  Concatenation[Token, Left, Right](left: left, right: right)
