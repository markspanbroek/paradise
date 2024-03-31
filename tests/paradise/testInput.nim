import std/unittest
import std/strutils
import std/os
import paradise/basics
import paradise/input
import ./examples/lexer

suite "string input":

  test "reads one character at a time":
    let input = Input.new("abc")
    check input.read() == success 'a'
    check input.read() == success 'b'
    check input.read() == success 'c'

  test "reads a zero character at end of string":
    let input = Input.new("x")
    check input.read() == success 'x'
    check input.read() == success '\0'

  test "fails when reading beyond end of string":
    let input = Input.new("")
    check input.read() == success '\0'
    let failure = input.read()
    check failure.isFailure
    check failure.error.msg.contains("reading beyond end of input")

  test "peeks ahead at the next character":
    let input = Input.new("abc")
    check input.peek() == success 'a'
    check input.peek() == success 'a'
    check input.read() == success 'a'
    check input.peek() == success 'b'
    check input.read() == success 'b'
    check input.peek() == success 'c'
    check input.read() == success 'c'
    check input.peek() == success '\0'
    check input.read() == success '\0'
    check input.peek().isFailure

  test "errors include line and column location":
    proc readUntilError(input: string): ref CatchableError =
      let input = Input.new(input)
      var outcome = input.read()
      while outcome.isSuccess:
        outcome = input.read()
      outcome.error
    check readUntilError("").msg.contains("(1, 1)")
    check readUntilError("abc").msg.contains("(1, 4)")
    check readUntilError("a\nb\nc").msg.contains("(3, 2)")

suite "token sequence input":

  let token1 = LexerToken(category: number, value: "1")
  let token2 = LexerToken(category: number, value: "2")
  let tokenA = LexerToken(category: text, value: "a")

  test "reads one token at a time":
    let input = Input.new(@[token1, token2, tokenA])
    check input.read() == success token1
    check input.read() == success token2
    check input.read() == success tokenA

  test "reads a special token at end of input":
    let input = Input.new(@[token1])
    check input.read() == success token1
    check input.read() == success LexerToken.endOfInput

  test "fails when reading beyond end of input":
    let input = Input.new(@[token1])
    check input.read() == success token1
    check input.read() == success LexerToken.endOfInput
    let failure = input.read()
    check failure.isFailure
    check failure.error.msg.contains("reading beyond end of input")

  test "peeks ahead at the next token":
    let input = Input.new(@[token1, token2, tokenA])
    check input.peek() == success token1
    check input.peek() == success token1
    check input.read() == success token1
    check input.peek() == success token2
    check input.read() == success token2
    check input.peek() == success tokenA
    check input.read() == success tokenA
    check input.peek() == success LexerToken.endOfInput
    check input.read() == success LexerToken.endOfInput
    check input.peek().isFailure

  test "errors include sequence index":
    proc readUntilError(input: seq[LexerToken]): ref CatchableError =
      let input = Input.new(input)
      var outcome = input.read()
      while outcome.isSuccess:
        outcome = input.read()
      outcome.error
    check readUntilError(@[]).msg.contains("(0, 0)")
    check readUntilError(@[token1, token2]).msg.contains("(0, 2)")
    check readUntilError(@[token1, token2, tokenA]).msg.contains("(0, 3)")

suite "file input":

  var input: Input[char]
  var file: File

  setup:
    file = open(currentSourcePath.parentDir / "examples" / "abc.txt")
    input = Input.new(file, bufferSize = 2)

  teardown:
    file.close()

  test "reads one character at a time":
    check input.read() == success 'a'
    check input.read() == success 'b'
    check input.read() == success 'c'

  test "reads a zero character at end of file":
    for _ in 0..<3: discard input.read()
    check input.read() == success '\0'

  test "fails when reading beyond end of file":
    for _ in 0..<3: discard input.read()
    check input.read() == success '\0'
    let failure = input.read()
    check failure.isFailure
    check failure.error.msg.contains("reading beyond end of input")

  test "peeks ahead at the next character":
    check input.peek() == success 'a'
    check input.peek() == success 'a'
    check input.read() == success 'a'
    check input.peek() == success 'b'
    check input.read() == success 'b'
    check input.peek() == success 'c'
    check input.read() == success 'c'
    check input.peek() == success '\0'
    check input.read() == success '\0'
    check input.peek().isFailure

  test "errors include line and column location":
    proc readUntilError(input: Input[char]): ref CatchableError =
      var outcome = input.read()
      while outcome.isSuccess:
        outcome = input.read()
      outcome.error
    check readUntilError(input).msg.contains("(1, 4)")

suite "input without peek function":

  var input: Input[int]

  setup:
    var count = 0
    let finish = 3
    proc read: ?!int =
      result = success count
      inc count
    proc ended: bool =
      count == finish
    proc location: Location =
      Location(line: 0, column: count)
    input = Input.new(read = read, ended = ended, location = location)

  test "reads one token at a time":
    check input.read() == success 0
    check input.read() == success 1
    check input.read() == success 2

  test "peeks ahead at the next token":
    check input.peek() == success 0
    check input.peek() == success 0
    check input.read() == success 0
    check input.peek() == success 1
    check input.read() == success 1
    check input.peek() == success 2
    check input.read() == success 2

  test "contains location":
    check $input.location() == "(0, 0)"
    discard input.read()
    check $input.location() == "(0, 1)"
    discard input.read()
    check $input.location() == "(0, 2)"

  test "location does not change when peeking":
    let before = input.location
    discard input.peek()
    let after = input.location
    check before == after

  test "ended does not change when peeking":
    let before = input.ended()
    discard input.peek()
    let after = input.ended()
    check before == after
