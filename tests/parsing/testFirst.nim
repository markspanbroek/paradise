import std/unittest
import parsing/grammar
import parsing/LL1
import ./examples/conversion
import ./examples/lexer

proc first[Token, Category; P: Parslet[Token, Category]](parslet: P): auto =
  parslet.update()
  parslet.first

suite "first character set":

  test "symbols":
    check first(symbol('a')) == {'a'}
    check first(symbol('!')) == {'!'}

  test "character sets":
    check first(symbol({'a'..'z'})) == {'a'..'z'}
    check first(symbol({'0'..'9'})) == {'0'..'9'}

  test "end of input":
    check first(finish()) == {'\0'}

  test "conversion":
    check first(symbol({'0'..'9'}).convert(charToInt)) == {'0'..'9'}

  test "concatenation":
    check first(symbol('a') & symbol('b')) == {'a'}
    check first(symbol({'0'..'9'}) & symbol('!')) == {'0'..'9'}

suite "first token set":

  let number = symbol(LexerToken, LexerCategory.number)
  let text = symbol(LexerToken, LexerCategory.text)

  test "symbols":
    check first(number) == {LexerCategory.number}
    check first(text) == {LexerCategory.text}

  test "character sets":
    let numberOrText = symbol(LexerToken, {LexerCategory.number, LexerCategory.text})
    check first(numberOrText) == {LexerCategory.number, LexerCategory.text}

  test "end of input":
    check first(finish(LexerToken)) == {LexerCategory.endOfInput}

  test "conversion":
    check first(number.convert(tokenToString)) == {LexerCategory.number}

  test "concatenation":
    check first(number & text) == {LexerCategory.number}
    check first(text & number) == {LexerCategory.text}
