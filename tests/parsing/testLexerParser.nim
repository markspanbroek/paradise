import std/unittest
import std/sequtils
import pkg/questionable/results
import parsing
import ./examples/lexer
import ./examples/conversion

import parsing/input

suite "lexer and parser":

  test "parses output of lexer":

    proc digitToLexerToken(digit: char): LexerToken =
      LexerToken(category: LexerCategory.number, value: $digit)

    let lexer = symbol({'0'..'9'}).convert(digitToLexerToken)
    let parser = symbol(LexerToken, LexerCategory.number).convert(tokenToString)

    let parsed = toSeq parser.tokenize(lexer.tokenize("123"))
    check parsed == @[success "1", success "2", success "3"]
