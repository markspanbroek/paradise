import ./parslet

export parslet.`$`

type Symbol* = object of Parslet
  character*: char

func symbol*(character: char): auto =
  Symbol(character: character, description: "'" & character & "'")
