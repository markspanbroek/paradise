import ./parslet

export parslet.`$`

type Symbol*[Token, Category] = object of Parslet[Token]
  category*: Category

func symbol*[Category](Token: type, category: Category): auto =
  Symbol[Token, Category](category: category, description: $category)

func symbol*(character: char): auto =
  Symbol[char, char](category: character, description: "'" & character & "'")
