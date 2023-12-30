type Parslet* = object
  description*: string

func `$`*(parslet: Parslet): string =
  parslet.description
