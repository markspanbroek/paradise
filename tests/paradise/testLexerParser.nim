import std/unittest
import std/sequtils
import pkg/questionable/results
import paradise
import ./examples/lexer
import ./examples/conversion

suite "lexer and parser":

  test "parses output of lexer":

    proc digitToLexerToken(parsed: char): LexerToken =
      LexerToken(category: LexerCategory.number, value: $parsed)

    proc finishToLexerToken(parse: char): LexerToken =
      LexerToken(category: LexerCategory.endOfInput)

    rule digit: symbol({'0'..'9'}) >> digitToLexerToken
    rule finishLexer: finish() >> finishToLexerToken
    rule lexer: digit | finishLexer

    rule number: symbol(LexerToken, LexerCategory.number)
    rule finishParser: symbol(LexerToken, LexerCategory.endOfInput)
    rule parser: number | finishParser >> tokenToString

    let parsed = toSeq parser.tokenize(lexer.tokenize("123"))
    check parsed == @[success "1", success "2", success "3", success "endOfInput"]
