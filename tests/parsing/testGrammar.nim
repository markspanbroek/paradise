import std/unittest
import parsing/grammar
import ./examples/lexer
import ./examples/conversion

suite "character grammars":

  test "symbols":
    check symbol('a') is Grammar[char]
    check symbol('!') is Grammar[char]

  test "character sets":
    check symbol({'a'..'z'}) is Grammar[char]
    check symbol({'0'..'9'}) is Grammar[char]

  test "end of input":
    check finish() is Grammar[char]

  test "conversion":
    check symbol({'0'..'9'}).convert(charToInt) is Grammar[char]

  test "concatenation":
    check symbol('a') & symbol('b') is Grammar[char]

  test "optional":
    check ?symbol('a') is Grammar[char]
    check ?(symbol({'0'..'9'}) & symbol('!')) is Grammar[char]

  test "recursive rules":
    let rule = recursive int
    check rule is Grammar[char]

suite "token grammars":

  let number = symbol(LexerToken, LexerCategory.number)
  let text = symbol(LexerToken, LexerCategory.text)

  test "symbols":
    check number is Grammar[LexerToken]
    check text is Grammar[LexerToken]

  test "token sets":
    check symbol(LexerToken, {LexerCategory.number, text}) is Grammar[LexerToken]

  test "end of input":
    check finish(LexerToken) is Grammar[LexerToken]

  test "conversion":
    check number.convert(tokenToString) is Grammar[LexerToken]

  test "concatenation":
    check number & text is Grammar[LexerToken]

  test "optional":
    check ?number is Grammar[LexerToken]
    check (?text & number) is Grammar[LexerToken]

  test "recursive rules":
    let rule = recursive(LexerToken, int)
    check rule is Grammar[LexerToken]
