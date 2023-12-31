import std/unittest
import parsing/basics
import parsing/grammar
import parsing/parser

suite "parser":

  test "symbols":
    check symbol('a').parse("a") == success 'a'
    check symbol('b').parse("b") == success 'b'
    check symbol('a').parse("b").isFailure
    check symbol('b').parse("a").isFailure
