type SequenceLocation* = object
  index: int

func init*(_: type SequenceLocation): SequenceLocation =
  SequenceLocation(index: 0)

func update*[Element](location: var SequenceLocation, element: Element) =
  inc location.index

func `$`*(location: SequenceLocation): string =
  "(" & $location.index & ")"

type TextLocation* = object
  line: int
  column: int

func init*(_: type TextLocation): TextLocation =
  TextLocation(line: 1, column: 1)

func update*(location: var TextLocation, character: char) =
  if character == '\n':
    inc location.line
    location.column = 1
  else:
    inc location.column

func `$`*(location: TextLocation): string =
  "(" & $location.line & ", " & $location.column & ")"
