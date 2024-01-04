import std/unittest
import parsing/grammar
import ./examples/lexer
import ./examples/conversion

suite "character grammars":

  test "symbols":
    check symbol('a') is Parslet[char]
    check symbol('!') is Parslet[char]

  test "character sets":
    check symbol({'a'..'z'}) is Parslet[char]
    check symbol({'0'..'9'}) is Parslet[char]

  test "end of input":
    check finish() is Parslet[char]

  test "conversion":
    check symbol({'0'..'9'}).convert(charToInt) is Parslet[char]

suite "token grammars":

  let number = symbol(LexerToken, LexerCategory.number)
  let text = symbol(LexerToken, LexerCategory.text)

  test "symbols":
    check number is Parslet[LexerToken]
    check text is Parslet[LexerToken]

  test "token sets":
    check symbol(LexerToken, {LexerCategory.number, text}) is Parslet[LexerToken]

  test "end of input":
    check finish(LexerToken) is Parslet[LexerToken]

  test "conversion":
    check number.convert(tokenToString) is Parslet[LexerToken]
