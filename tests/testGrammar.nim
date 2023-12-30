import std/unittest
import parsing/grammar
import parsing/parslet

suite "grammar":

  test "symbols":
    check symbol('a') is Parslet
    check symbol('!') is Parslet
