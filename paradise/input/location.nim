type Location* = object
  line*: int
  column*: int

func `$`*(location: Location): string =
  "(" & $location.line & ", " & $location.column & ")"
