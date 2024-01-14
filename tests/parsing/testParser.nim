import std/unittest
import std/strutils
import std/sequtils
import pkg/questionable
import pkg/questionable/results
import parsing
import parsing/input
import ./examples/lexer
import ./examples/conversion

suite "parse characters":

  test "symbols":
    check symbol('a').parse("a") == success 'a'
    check symbol('b').parse("b") == success 'b'
    check symbol('a').parse("b").isFailure
    check symbol('b').parse("a").isFailure

  test "character sets":
    check symbol({'a'..'z'}).parse("k") == success 'k'
    check symbol({'a'..'z'}).parse("5").isFailure

  test "end of input":
    check finish().parse("") == success '\0'
    check finish().parse("a").isFailure

  test "conversion":
    check symbol({'0'..'9'}).convert(charToInt).parse("5") == success 5
    check symbol({'0'..'9'}).convert(charToInt).parse("a").isFailure

  test "concatenation":
    let ab = symbol('a') & symbol('b')
    check ab.parse("ab") == success ('a', 'b')
    check ab.parse("xb").error.msg == "expected: 'a' (1, 1)"
    check ab.parse("ax").error.msg == "expected: 'b' (1, 2)"

  test "nested concatenation":
    let abcd = symbol('a') & symbol('b') & symbol('c') & symbol('d')
    check abcd.parse("abcd") == success ('a', 'b', 'c', 'd')
    check abcd.parse("abc").error.msg == "expected: 'd' (1, 4)"

  test "optional":
    check (?symbol('a')).parse("a") == success some 'a'
    check (?symbol('a')).parse("") == success none char
    check (?symbol('a') & symbol('b')).parse("ab") == success (some 'a', 'b')
    check (?symbol('a') & symbol('b')).parse("b") == success (none char, 'b')

  test "recursive rules":
    let x = recursive int
    proc length(parsed: ?(char, int)): int = (parsed.?[1] + 1) |? 0
    define x: (?(symbol('x') & x)).convert(length)
    check x.parse("") == success 0
    check x.parse("x") == success 1
    check x.parse("xx") == success 2
    check x.parse("xxx") == success 3

  test "iterative parsing":
    let parser = symbol({'0'..'9'}).convert(charToInt)
    let parsed = toSeq(parser.tokenize("123"))
    check parsed == @[success 1, success 2, success 3]

  test "iterative parsing stops on error":
    let parser = symbol({'0'..'9'}).convert(charToInt)
    let parsed = toSeq(parser.tokenize("12x3"))
    check parsed.len == 3
    check parsed[0] == success 1
    check parsed[1] == success 2
    check parsed[2].isFailure

  test "errors include line and column location":
    let grammar = symbol('o')
    let input = Input.new("o\no\noxo")
    for _ in 1..5: # read up to 'x'
      discard input.read()
    let error = grammar.parse(input).error
    check error.msg.contains("(3, 2)")

suite "parse tokens":

  let token1 = LexerToken(category: number, value: "1")
  let token2 = LexerToken(category: number, value: "2")
  let tokenA = LexerToken(category: text, value: "a")

  test "symbols":
    let number = symbol(LexerToken, LexerCategory.number)
    let text = symbol(LexerToken, LexerCategory.text)
    check number.parse(@[token1]) == success token1
    check number.parse(@[token2]) == success token2
    check number.parse(@[tokenA]).isFailure
    check text.parse(@[token1]).isFailure
    check text.parse(@[token2]).isFailure
    check text.parse(@[tokenA]) == success tokenA

  test "symbol sets":
    let numberOrText = symbol(LexerToken, {LexerCategory.number, text})
    check numberOrText.parse(@[token1]) == success token1
    check numberOrText.parse(@[token2]) == success token2
    check numberOrText.parse(@[tokenA]) == success tokenA

  test "end of input":
    let endToken = LexerToken(category: endOfInput)
    check finish(LexerToken).parse(@[]) == success endToken
    check finish(LexerToken).parse(@[token1]).isFailure

  test "conversion":
    let text = symbol(LexerToken, LexerCategory.text).convert(tokenToString)
    let tokenAbc = LexerToken(category: text, value: "abc")
    let token123 = LexerToken(category: number, value: "123")
    check text.parse(@[tokenAbc]) == success "abc"
    check text.parse(@[token123]).isFailure

  test "concatenation":
    let number = symbol(LexerToken, LexerCategory.number)
    let text = symbol(LexerToken, LexerCategory.text)
    let numberAndText = number & text
    check numberAndText.parse(@[token1, tokenA]) == success (token1, tokenA)
    check numberAndText.parse(@[token1, token2]).error.msg == "expected: text (0, 1)"
    check numberAndText.parse(@[tokenA, tokenA]).error.msg == "expected: number (0, 0)"

  test "optional":
    let number = symbol(LexerToken, LexerCategory.number)
    let text = symbol(LexerToken, LexerCategory.text)
    check (?number).parse(@[token1]) == success some token1
    check (?number).parse(@[]) == success none LexerToken
    check (?number & text).parse(@[token1, tokenA]) == success (some token1, tokenA)
    check (?number & text).parse(@[tokenA]) == success (none LexerToken, tokenA)

  test "iterative parsing":
    let number = symbol(LexerToken, {LexerCategory.number})
    let parser = number.convert(tokenToString)
    let parsed = toSeq(parser.tokenize(@[token1, token2]))
    check parsed == @[success "1", success "2"]

  test "iterative parsing stops on error":
    let number = symbol(LexerToken, {LexerCategory.number})
    let parser = number.convert(tokenToString)
    let parsed = toSeq(parser.tokenize(@[token1, tokenA, token2]))
    check parsed.len == 2
    check parsed[0] == success "1"
    check parsed[1].isFailure

  test "errors include sequence index":
    let grammar = symbol(LexerToken, LexerCategory.number)
    let input = Input.new(@[token1, token2, tokenA])
    for _ in 1..2: # read up to "a"
      discard input.read()
    let error = grammar.parse(input).error
    check error.msg.contains("(0, 2)")
