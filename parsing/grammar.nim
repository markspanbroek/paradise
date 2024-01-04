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

func convert*[Token; P: Parslet[Token], From, To](parslet: P, convert: Converter[From, To]): auto =
  Conversion[Token, P, From, To](operand: parslet, convert: convert)
