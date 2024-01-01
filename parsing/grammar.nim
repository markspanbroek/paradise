import ./parslet
import ./characters

export parslet.`$`

type Symbol*[Token, Category] = object of Parslet[Token]
  category*: Category

func symbol*[Category](Token: type, category: Category): auto =
  when Category is char:
    let description = "'" & category & "'"
  else:
    let description = $category
  Symbol[Token, Category](category: category, description: description)

func symbol*(character: char): auto =
  symbol(char, character)

func finish*(Token: type = char): auto =
  mixin category, endOfInput
  symbol(Token, Token.endOfInput.category)
