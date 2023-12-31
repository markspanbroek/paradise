type Parslet* = object of RootObj
  description*: string

func `$`*[P: Parslet](parslet: P): string =
  parslet.description
