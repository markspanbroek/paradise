import std/unittest
import parsing/grammar

suite "grammar descriptions":

  test "symbol":
    check $symbol('a') == "'a'"
    check $symbol('!') == "'!'"
    check $symbol('\'') == "'''"
