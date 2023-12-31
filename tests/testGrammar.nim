import std/unittest
import parsing/grammar
import parsing/parslet
import ./examples/lexer

suite "character grammars":

  test "symbols":
    check symbol('a') is Parslet[char]
    check symbol('!') is Parslet[char]

suite "token grammars":

  let number = symbol(LexerToken, LexerCategory.number)
  let text = symbol(LexerToken, LexerCategory.text)

  test "symbols":
    check number is Parslet[LexerToken]
    check text is Parslet[LexerToken]
