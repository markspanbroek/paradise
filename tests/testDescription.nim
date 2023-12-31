import std/unittest
import parsing/grammar
import ./examples/lexer

suite "grammar descriptions":

  test "character symbol":
    check $symbol('a') == "'a'"
    check $symbol('!') == "'!'"
    check $symbol('\'') == "'''"

  test "token symbol":
    check $symbol(LexerToken, LexerCategory.text) == "text"
    check $symbol(LexerToken, LexerCategory.number) == "number"
