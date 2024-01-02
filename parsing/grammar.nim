import ./parslet
import ./characters

export parslet.`$`

type Symbol*[Token, Category] = object of Parslet[Token]
  category*: Category

func symbol*[Category](Token: type, category: Category): auto =
  Symbol[Token, Category](category: category, description: $category)

func symbol*(Token: type, category: char): auto =
  Symbol[Token, char](category: category, description: "'" & category & "'")

func symbol*(character: char): auto =
  symbol(char, character)

func finish*(Token: type = char): auto =
  mixin category, endOfInput
  symbol(Token, Token.endOfInput.category)
