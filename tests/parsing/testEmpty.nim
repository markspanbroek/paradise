import std/unittest
import parsing/grammar
import parsing/LL1
import ./examples/conversion

suite "empty":

  proc canBeEmpty[Token, Category; P: Parslet[Token, Category]](parslet: P): auto =
    parslet.update()
    parslet.canBeEmpty

  test "symbols":
    check not canBeEmpty(symbol('a'))
    check not canBeEmpty(symbol('!'))

  test "character sets":
    check not canBeEmpty(symbol({'a'..'z'}))
    check not canBeEmpty(symbol({'0'..'9'}))

  test "end of input":
    check not canBeEmpty(finish())

  test "optional":
    check canBeEmpty(?symbol('a'))

  test "concatenation":
    check canBeEmpty(?symbol('a') & ?symbol('b'))
    check not canBeEmpty(?symbol('a') & symbol('b'))
    check not canBeEmpty(symbol('a') & ?symbol('b'))
    check not canBeEmpty(symbol('a') & symbol('b'))

  test "conversion":
    check canBeEmpty((?symbol('5')).convert(charToInt))
    check not canBeEmpty(symbol('5').convert(charToInt))
