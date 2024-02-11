import std/unittest
import std/strutils
import parsing/grammar
import ./examples/lexer
import ./examples/conversion

suite "grammar descriptions":

  test "character symbol":
    check $symbol('a') == "'a'"
    check $symbol('!') == "'!'"
    check $symbol('\'') == "'''"

  test "token symbol":
    check $symbol(LexerToken, LexerCategory.text) == "text"
    check $symbol(LexerToken, LexerCategory.number) == "number"

  test "character sets":
    check $symbol({'1'..'5'}) == "{'1', '2', '3', '4', '5'}"

  test "token sets":
    check $symbol(LexerToken, {number, text}) == "{number, text}"

  test "end of input":
    check $finish() == "'\0'"
    check $finish(LexerToken) == "endOfInput"

  test "conversion":
    check $symbol('5').convert(charToInt) == "'5'"
    check $symbol({'1'..'5'}).convert(charToInt) == "{'1', '2', '3', '4', '5'}"

  test "concatenation":
    check $(symbol('a') & symbol('b')) == "('a' & 'b')"

  test "optional":
    check $(?symbol('a')) == "'a'?"
    check $(?(symbol('x') & symbol('!'))) == "('x' & '!')?"

  test "repetition *":
    check $(*symbol('a')) == "'a'*"
    check $(*(symbol('x') & symbol('!'))) == "('x' & '!')*"

  test "repetition +":
    check $(+symbol('a')) == "'a'+"
    check $(+(symbol('x') & symbol('!'))) == "('x' & '!')+"

  test "recursive rule with name":
    check $recursive("foo", int) == "foo"
    check $recursive("bar", LexerToken, int) == "bar"

  test "recursive rule without name":
    check ($recursive(int)).startsWith("recursive")
    check ($recursive(LexerToken, int)).startsWith("recursive")
    check $recursive(int) != $recursive(int)
    check $recursive(LexerToken, int) != $recursive(LexerToken, int)

  test "alternatives":
    check $(symbol('a') | symbol('b')) == "('a' | 'b')"
    check $(symbol('a') | symbol('b') | symbol('c') | symbol('d')) == "('a' | 'b' | 'c' | 'd')"
