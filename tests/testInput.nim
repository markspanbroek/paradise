import std/unittest
import parsing/basics
import parsing/input
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
    check failure.error.msg == "reading beyond end of input"

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
    check failure.error.msg == "reading beyond end of input"
