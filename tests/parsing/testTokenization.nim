import std/unittest
import std/strutils
import pkg/questionable/results
import parsing

suite "tokenization":

  let digit = symbol({'0'..'9'})

  test "parses tokens repeatedly":
    let tokens = digit.tokenize("123")
    check tokens.read() == success '1'
    check tokens.read() == success '2'
    check tokens.read() == success '3'
    check tokens.read().isFailure

  test "peeks ahead at the next token":
    let tokens = digit.tokenize("123")
    check tokens.peek() == success '1'
    check tokens.peek() == success '1'
    check tokens.read() == success '1'
    check tokens.peek() == success '2'
    check tokens.read() == success '2'
    check tokens.peek() == success '3'
    check tokens.read() == success '3'
    check tokens.peek().isFailure
    check tokens.read().isFailure

  test "errors include location":
    let tokens = digit.tokenize("1x3")
    check tokens.read() == success '1'
    check tokens.peek().error.msg.contains("(1, 2)")
    check tokens.read().error.msg.contains("(1, 2)")

  test "location does not change when peeking":
    let tokens = digit.tokenize("123")
    let before = tokens.location
    discard tokens.peek()
    let after = tokens.location
    check before == after

  test "ended does not change when peeking":
    let tokens = digit.tokenize("1")
    let before = tokens.ended()
    discard tokens.peek()
    let after = tokens.ended()
    check before == after
