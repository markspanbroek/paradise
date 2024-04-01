import std/unittest
import std/strutils
import std/sequtils
import std/os
import pkg/questionable
import pkg/questionable/results
import paradise
import paradise/input
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
    check (symbol({'0'..'9'}) >> charToInt).parse("5") == success 5
    check (symbol({'0'..'9'}) >> charToInt).parse("a").isFailure

  test "concatenation":
    let ab = symbol('a') & symbol('b')
    check ab.parse("ab") == success ('a', 'b')
    check ab.parse("xb").error.msg == "expected: 'a' (1, 1)"
    check ab.parse("ax").error.msg == "expected: 'b' (1, 2)"

  test "nested concatenation":
    let abcd = symbol('a') & symbol('b') & symbol('c') & symbol('d')
    check abcd.parse("abcd") == success ('a', 'b', 'c', 'd')
    check abcd.parse("abc").error.msg == "expected: 'd' (1, 4)"

  test "concatenation of same parslet":
    let letter = symbol({'a'..'z'})
    let letters = letter & letter & letter
    check letters.parse("abc") == success ('a', 'b', 'c')

  test "concatenation of same concatenation":
    let letter = symbol({'a'..'z'})
    let letters = letter & letter
    let concatenation = letters & letters
    check concatenation.parse("abcd") == success ('a', 'b', 'c', 'd')

  test "optional":
    check (?symbol('a')).parse("a") == success some 'a'
    check (?symbol('a')).parse("") == success none char
    check (?symbol('a') & symbol('b')).parse("ab") == success (some 'a', 'b')
    check (?symbol('a') & symbol('b')).parse("b") == success (none char, 'b')

  test "repetition *":
    let repetition = *symbol({'0'..'9'}) & symbol('!')
    check repetition.parse("!") == success ("", '!')
    check repetition.parse("1!") == success ("1", '!')
    check repetition.parse("42!") == success ("42", '!')

  test "repetition +":
    let repetition = +symbol({'0'..'9'}) & symbol('!')
    check repetition.parse("!").isFailure
    check repetition.parse("1!") == success ("1", '!')
    check repetition.parse("42!") == success ("42", '!')

  test "recursive rules":
    let x = recursive int
    proc length(parsed: ?(char, int)): int = (parsed.?[1] + 1) |? 0
    define x: ?(symbol('x') & x) >> length
    check x.parse("") == success 0
    check x.parse("x") == success 1
    check x.parse("xx") == success 2
    check x.parse("xxx") == success 3
    check x.parse("x".repeat(4000)) == success 4000

  test "alternatives":
    let alternatives = symbol('a') | symbol('b') | symbol('c')
    check alternatives.parse("a") == success 'a'
    check alternatives.parse("b") == success 'b'
    check alternatives.parse("c") == success 'c'
    check alternatives.parse("d").isFailure

  test "optional alternatives":
    let alternatives = (?symbol('a') & symbol('b')) | (?symbol('c') & symbol('d'))
    check alternatives.parse("ab") == success (some 'a', 'b')
    check alternatives.parse("cd") == success (some 'c', 'd')
    check alternatives.parse("b") == success (none char, 'b')
    check alternatives.parse("d") == success (none char, 'd')

  test "alternative that can only be chosen by its follow set":
    proc optionToInt(c: ?char): int = (c.?charToInt() |? -1)
    let one = symbol('1') >> charToInt
    let two = ?symbol('2') >> optionToInt
    let three = symbol('3') >> charToInt
    let alternatives = (one | two) & three
    check alternatives.parse("13") == success (1, 3)
    check alternatives.parse("23") == success (2, 3)
    check alternatives.parse("3") == success (-1, 3)

  test "iterative parsing":
    let parser = symbol({'0'..'9'}) >> charToInt
    let parsed = toSeq(parser.tokenize("123"))
    check parsed == @[success 1, success 2, success 3]

  test "iterative parsing stops on error":
    let parser = symbol({'0'..'9'}) >> charToInt
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
  let tokenT = LexerToken(category: text, value: "text")
  let tokenN = LexerToken(category: name, value: "name")
  let tokenEnd = LexerToken(category: endOfInput)

  test "symbols":
    let number = symbol(LexerToken, LexerCategory.number)
    let text = symbol(LexerToken, LexerCategory.text)
    check number.parse(@[token1]) == success token1
    check number.parse(@[token2]) == success token2
    check number.parse(@[tokenT]).isFailure
    check text.parse(@[token1]).isFailure
    check text.parse(@[token2]).isFailure
    check text.parse(@[tokenT]) == success tokenT

  test "symbol sets":
    let numberOrText = symbol(LexerToken, {LexerCategory.number, text})
    check numberOrText.parse(@[token1]) == success token1
    check numberOrText.parse(@[token2]) == success token2
    check numberOrText.parse(@[tokenT]) == success tokenT

  test "end of input":
    let endToken = LexerToken(category: endOfInput)
    check finish(LexerToken).parse(@[]) == success endToken
    check finish(LexerToken).parse(@[token1]).isFailure

  test "conversion":
    let text = symbol(LexerToken, LexerCategory.text) >> tokenToString
    let tokenAbc = LexerToken(category: text, value: "abc")
    let token123 = LexerToken(category: number, value: "123")
    check text.parse(@[tokenAbc]) == success "abc"
    check text.parse(@[token123]).isFailure

  test "concatenation":
    let number = symbol(LexerToken, LexerCategory.number)
    let text = symbol(LexerToken, LexerCategory.text)
    let numberAndText = number & text
    check numberAndText.parse(@[token1, tokenT]) == success (token1, tokenT)
    check numberAndText.parse(@[token1, token2]).error.msg == "expected: text (0, 1)"
    check numberAndText.parse(@[tokenT, tokenT]).error.msg == "expected: number (0, 0)"

  test "optional":
    let number = symbol(LexerToken, LexerCategory.number)
    let text = symbol(LexerToken, LexerCategory.text)
    check (?number).parse(@[token1]) == success some token1
    check (?number).parse(@[]) == success none LexerToken
    check (?number & text).parse(@[token1, tokenT]) == success (some token1, tokenT)
    check (?number & text).parse(@[tokenT]) == success (none LexerToken, tokenT)

  test "repetition *":
    let number = symbol(LexerToken, LexerCategory.number)
    let text = symbol(LexerToken, LexerCategory.text)
    let repetition = *number & text
    let empty = seq[LexerToken].default
    check repetition.parse(@[tokenT]) == success (empty, tokenT)
    check repetition.parse(@[token1, tokenT]) == success (@[token1], tokenT)
    check repetition.parse(@[token1, token2, tokenT]) == success (@[token1, token2], tokenT)

  test "repetition +":
    let number = symbol(LexerToken, LexerCategory.number)
    let text = symbol(LexerToken, LexerCategory.text)
    let repetition = +number & text
    check repetition.parse(@[tokenT]).isFailure
    check repetition.parse(@[token1, tokenT]) == success (@[token1], tokenT)
    check repetition.parse(@[token1, token2, tokenT]) == success (@[token1, token2], tokenT)

  test "recursive rules":
    let numbers = recursive(LexerToken, int)
    let number = symbol(LexerToken, LexerCategory.number)
    proc length(parsed: ?(LexerToken, int)): int = (parsed.?[1] + 1) |? 0
    define numbers: ?(number & numbers) >> length
    check numbers.parse(@[]) == success 0
    check numbers.parse(@[token1]) == success 1
    check numbers.parse(@[token1, token2]) == success 2
    check numbers.parse(@[token1, token2, token1]) == success 3

  test "alternatives":
    let number = symbol(LexerToken, LexerCategory.number)
    let finish = symbol(LexerToken, LexerCategory.endOfInput)
    let alternatives = number | finish
    check alternatives.parse(@[token1]) == success token1
    check alternatives.parse(@[token2]) == success token2
    check alternatives.parse(@[]) == success tokenEnd
    check alternatives.parse(@[tokenT]).isFailure

  test "optional alternatives":
    let number = symbol(LexerToken, LexerCategory.number)
    let text = symbol(LexerToken, LexerCategory.text)
    let name = symbol(LexerToken, LexerCategory.name)
    let finish = symbol(LexerToken, LexerCategory.endOfInput)
    let alternatives = (?number & name) | (?text & finish)
    check alternatives.parse(@[token1, tokenN]) == success (some token1, tokenN)
    check alternatives.parse(@[tokenT]) == success (some tokenT, tokenEnd)
    check alternatives.parse(@[tokenN]) == success (none LexerToken, tokenN)
    check alternatives.parse(@[]) == success (none LexerToken, tokenEnd)

  test "iterative parsing":
    let number = symbol(LexerToken, {LexerCategory.number})
    let parser = number >> tokenToString
    let parsed = toSeq(parser.tokenize(@[token1, token2]))
    check parsed == @[success "1", success "2"]

  test "iterative parsing stops on error":
    let number = symbol(LexerToken, {LexerCategory.number})
    let parser = number >> tokenToString
    let parsed = toSeq(parser.tokenize(@[token1, tokenT, token2]))
    check parsed.len == 2
    check parsed[0] == success "1"
    check parsed[1].isFailure

  test "errors include sequence index":
    let grammar = symbol(LexerToken, LexerCategory.number)
    let input = Input.new(@[token1, token2, tokenT])
    for _ in 1..2: # read up to "a"
      discard input.read()
    let error = grammar.parse(input).error
    check error.msg.contains("(0, 2)")

suite "parsing files":

  test "parses file input":
    let file = open(currentSourcePath.parentDir / "examples" / "abc.txt")
    let grammar = +symbol({'a'..'z'}) & finish()
    check grammar.parse(file) == success ("abc", '\0')
    file.close()
