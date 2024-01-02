import std/unittest
import std/strutils
import parsing/basics
import parsing/grammar
import parsing/parser
import parsing/input
import ./examples/lexer

suite "parse characters":

  test "symbols":
    check symbol('a').parse("a") == success 'a'
    check symbol('b').parse("b") == success 'b'
    check symbol('a').parse("b").isFailure
    check symbol('b').parse("a").isFailure

  test "end of input":
    check finish().parse("") == success '\0'
    check finish().parse("a").isFailure

  test "errors include line and column location":
    let parser = symbol('o')
    let input = Input.new("o\no\noxo")
    for _ in 1..5: # read up to 'x'
      discard input.read()
    let error = parser.parse(input).error
    check error.msg.contains("(3, 2)")

suite "parse tokens":

  let token1 = LexerToken(category: number, value: "1")
  let token2 = LexerToken(category: number, value: "2")
  let tokenA = LexerToken(category: text, value: "a")

  test "symbols":
    let number = symbol(LexerToken, LexerCategory.number)
    let text = symbol(LexerToken, LexerCategory.text)
    check number.parse(@[token1]) == success token1
    check number.parse(@[token2]) == success token2
    check number.parse(@[tokenA]).isFailure
    check text.parse(@[token1]).isFailure
    check text.parse(@[token2]).isFailure
    check text.parse(@[tokenA]) == success tokenA

  test "end of input":
    let endToken = LexerToken(category: endOfInput)
    check finish(LexerToken).parse(@[]) == success endToken
    check finish(LexerToken).parse(@[token1]).isFailure

  test "errors include sequence index":
    let parser = symbol(LexerToken, LexerCategory.number)
    let input = Input.new(@[token1, token2, tokenA])
    for _ in 1..2: # read up to "a"
      discard input.read()
    let error = parser.parse(input).error
    check error.msg.contains("(2)")
