import std/unittest
import parsing/basics
import parsing/input

suite "string input":

  test "reads one character at a time":
    let input = Input.new("abc")
    check input.read() == success 'a'
    check input.read() == success 'b'
    check input.read() == success 'c'

  test "reads a zero character at end of string":
    let input = Input.new("x")
    check input.read() == success 'x'
    check input.read() == success '\0'

  test "fails when reading beyond end of string":
    let input = Input.new("")
    check input.read() == success '\0'
    let failure = input.read()
    check failure.isFailure
    check failure.error.msg == "reading beyond end of string"
