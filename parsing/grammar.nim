import ./parslet

export parslet.`$`

func symbol*(symbol: char): auto =
  Parslet(description: "'" & symbol & "'")
