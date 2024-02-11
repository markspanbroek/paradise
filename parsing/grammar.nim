import ./basics
import ./characters
import ./tuples
import ./automaton

type Grammar*[Token] = ref object of RootObj

type Parslet*[Token, Category] = ref object of Grammar[Token]
  canBeEmpty*: bool
  first*: set[Category]
  last*: HashSet[Parslet[Token, Category]]
  follow*: set[Category]

func hash*[Token, Category](parslet: Parslet[Token, Category]): Hash =
  hash(addr parslet[])

func `==`*[Token, Category](a, b: Parslet[Token, Category]): bool =
  (addr a[]) == (addr b[])

type Symbol*[Token, Category] = ref object of Parslet[Token, Category]
  categories*: set[Category]
  description: string
  output*: ?!Token

func `$`*(symbol: Symbol): string =
  symbol.description

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
  Conversion*[Token, Category, Operand, From, To] = ref object of Parslet[Token, Category]
    operand*: Operand
    convert*: Converter[From, To]
    output*: ?!To
  Converter[From, To] = proc(input: From): To {.noSideEffect.}

func `$`*(conversion: Conversion): string =
  $conversion.operand

func convert*[Token, Category; Operand: Parslet[Token, Category], From, To](operand: Operand, convert: Converter[From, To]): auto =
  Conversion[Token, Category, Operand, From, To](operand: operand, convert: convert)

type Concatenation*[Token, Category, Left, Right, Output] = ref object of Parslet[Token, Category]
  left*: Left
  right*: Right
  output*: ?!Output

func `$`*(concatenation: Concatenation): string =
  "(" & $concatenation.left & " & " & $concatenation.right & ")"

func `&`*[Token, Category; Left, Right: Parslet[Token, Category]](left: Left, right: Right): auto =
  when Left is Concatenation:
    type Output = typeof(!left.output & !right.output)
  else:
    type Output = typeof((!left.output, !right.output))
  Concatenation[Token, Category, Left, Right, Output](left: left, right: right)

type Alternatives*[Token, Category, Choices, Output] = ref object of Parslet[Token, Category]
  choices*: Choices
  parseClosures*: array[Category.high, proc(automaton: Automaton[Token])]
  output*: ?!Output

func `$`*(alternatives: Alternatives): string =
  result &= "("
  var first = true
  for choice in alternatives.choices.fields:
    if first:
      first = false
    else:
      result &= " | "
    result &= $choice
  result &= ")"

func `|`*[Token, Category; A, B: Parslet[Token, Category]](a: A, b: B): auto =
  when typeof(!a.output) is typeof(!b.output):
    type Output = typeof(!b.output)
  else:
    when typeof(!b.output) is typeof(!a.output):
      type Output = typeof(!a.output)
    else:
      {.error: "output types do not match".}
  when A is Alternatives:
    type Choices = typeof(A.choices) & B
    Alternatives[Token, Category, Choices, Output](choices: a.choices & b)
  else:
    type Choices = (A, B)
    Alternatives[Token, Category, Choices, Output](choices: (a, b))

type Optional*[Token, Category, Operand, Output] = ref object of Parslet[Token, Category]
  operand*: Operand
  output*: ?!Output

func `$`*(optional: Optional): string =
  $optional.operand & "?"

func `?`*[Token, Category; Operand: Parslet[Token, Category]](operand: Operand): auto =
  type Output = ?typeof(!operand.output)
  Optional[Token, Category, Operand, Output](operand: operand)

type Recursion*[Token, Category, Output] = ref object of Parslet[Token, Category]
  updateClosure*: proc(again: var bool) {.noSideEffect.}
  parseClosure*: proc(automaton: Automaton[Token])
  description: string
  output*: ?!Output

func `$`*(rule: Recursion): string =
  rule.description

func recursive*(name: string, Token, Output: type): auto =
  mixin category
  type Category = typeof(Token.default.category)
  Recursion[Token, Category, Output](description: name)

func recursive*(name: string, Output: type): auto =
  recursive(name, char, Output)

var count: int

proc recursive*(Token, Output: type): auto =
  inc count
  recursive("recursive" & $count, Token, Output)

proc recursive*(Output: type): auto =
  recursive(char, Output)
