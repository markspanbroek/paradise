import std/unittest
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
