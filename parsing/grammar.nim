import ./parslet
import ./characters

export parslet.`$`

type Symbol*[Token, Category] = object of Parslet[Token]
  categories*: set[Category]

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
  Conversion*[Token, Operand, From, To] = object of Parslet[Token]
    operand*: Operand
    convert*: Converter[From, To]
  Converter[From, To] = proc(input: From): To {.noSideEffect.}

func convert*[Token; P: Parslet[Token], From, To](parslet: P, convert: Converter[From, To]): auto =
  Conversion[Token, P, From, To](operand: parslet, convert: convert, description: parslet.description)
