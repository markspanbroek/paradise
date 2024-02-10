import ./basics
import ./characters
import ./tuples
import ./automaton

type Grammar*[Token] = ref object of RootObj

type Parslet*[Token, Category] = ref object of Grammar[Token]
  canBeEmpty*: bool
  first*: set[Category]

type Symbol*[Token, Category] = ref object of Parslet[Token, Category]
  categories*: set[Category]
  description*: string
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

type Optional*[Token, Category, Operand, Output] = ref object of Parslet[Token, Category]
  operand*: Operand
  output*: ?!Output

func `$`*(optional: Optional): string =
  $optional.operand & "?"

func `?`*[Token, Category; Operand: Parslet[Token, Category]](operand: Operand): auto =
  type Output = ?typeof(!operand.output)
  Optional[Token, Category, Operand, Output](operand: operand)

type Recursion*[Token, Category, Output] = ref object of Parslet[Token, Category]
  updateClosure*: proc() {.noSideEffect.}
  parseClosure*: proc(automaton: Automaton[Token])
  output*: ?!Output

func recursive*(Token, Output: type): auto =
  mixin category
  type Category = typeof(Token.default.category)
  Recursion[Token, Category, Output]()

func recursive*(Output: type): auto =
  recursive(char, Output)
