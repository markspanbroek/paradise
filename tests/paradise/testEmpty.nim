import std/unittest
import pkg/questionable
import paradise/grammar
import paradise/recursion
import paradise/LL1
import ./examples/conversion

suite "empty":

  proc canBeEmpty[Token; G:Grammar[Token]](grammar: G): bool =
    grammar.update()
    grammar.canBeEmpty

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
    check canBeEmpty(?symbol('5') >> charToInt)
    check not canBeEmpty(symbol('5') >> charToInt)

  test "recursive rules":
    let a = recursive char
    define a: symbol('a')
    check not canBeEmpty a

    let b = recursive ?char
    define b: ?symbol('b')
    check canBeEmpty b

  test "alternatives":
    check not canBeEmpty symbol('a') | symbol('b')
    check canBeEmpty ?symbol('a') | ?symbol('b')

  test "repetition *":
    check canBeEmpty(*symbol('a'))
    check canBeEmpty(*(symbol('a') & symbol('b')))

  test "repetition +":
    check not canBeEmpty(+symbol('a'))
    check canBeEmpty(+(?symbol('a')))
