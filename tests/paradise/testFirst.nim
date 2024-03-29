import std/unittest
import pkg/questionable
import paradise/grammar
import paradise/LL1
import paradise/recursion
import ./examples/conversion
import ./examples/lexer

proc first(grammar: Grammar): auto =
  grammar.update()
  grammar.first

suite "first character set":

  test "symbols":
    check first(symbol('a')) == {'a'}
    check first(symbol('!')) == {'!'}

  test "character sets":
    check first(symbol({'a'..'z'})) == {'a'..'z'}
    check first(symbol({'0'..'9'})) == {'0'..'9'}

  test "end of input":
    check first(finish()) == {'\0'}

  test "conversion":
    check first(symbol({'0'..'9'}) >> charToInt) == {'0'..'9'}

  test "optional":
    check first((?symbol('a'))) == {'a'}
    check first(?(symbol('a') & symbol('b'))) == {'a'}

  test "repetition *":
    check first(*symbol('a')) == {'a'}
    check first(*symbol('a') & symbol('b')) == {'a', 'b'}
    check first(*symbol('a') & symbol('b') & symbol('c')) == {'a', 'b'}
    check first(*symbol('a') & *symbol('b') & symbol('c')) == {'a', 'b', 'c'}

  test "repetition +":
    check first((+symbol('a'))) == {'a'}
    check first((+symbol('a') & symbol('b'))) == {'a'}
    check first((+(symbol('a') & symbol('b')))) == {'a'}

  test "concatenation":
    check first(symbol('a') & symbol('b')) == {'a'}
    check first(symbol({'0'..'9'}) & symbol('!')) == {'0'..'9'}
    check first((?symbol('a') & symbol('b'))) == {'a', 'b'}
    check first((?symbol('a') & symbol('b') & symbol('c'))) == {'a', 'b'}
    check first((?symbol('a') & ?symbol('b') & symbol('c'))) == {'a', 'b', 'c'}

  test "recursive rules":
    let rule = recursive int
    proc count(parsed: (?int, char)): int = (parsed[0] |? 0) + 1
    define rule: ?rule & symbol('x') >> count
    check first(rule) == {'x'}

  test "alternatives":
    check first((symbol('a') | symbol('b'))) == {'a', 'b'}
    check first(((symbol('a') & symbol('b')) | (symbol('c') & symbol('d')))) == {'a', 'c'}

suite "first token set":

  let number = symbol(LexerToken, LexerCategory.number)
  let text = symbol(LexerToken, LexerCategory.text)

  test "symbols":
    check first(number) == {LexerCategory.number}
    check first(text) == {LexerCategory.text}

  test "character sets":
    let numberOrText = symbol(LexerToken, {LexerCategory.number, LexerCategory.text})
    check first(numberOrText) == {LexerCategory.number, LexerCategory.text}

  test "end of input":
    check first(finish(LexerToken)) == {LexerCategory.endOfInput}

  test "conversion":
    check first(number >> tokenToString) == {LexerCategory.number}

  test "repetition *":
    check first(*number) == {LexerCategory.number}
    check first(*number & text) == {LexerCategory.number, LexerCategory.text}

  test "repetition +":
    check first(+number) == {LexerCategory.number}
    check first(+number & text) == {LexerCategory.number}
    check first(+(number & text)) == {LexerCategory.number}

  test "concatenation":
    check first(number & text) == {LexerCategory.number}
    check first(text & number) == {LexerCategory.text}

  test "recursive rules":
    let rule = recursive(LexerToken, int)
    proc count(parsed: (?int, LexerToken)): int = (parsed[0] |? 0) + 1
    define rule: ?rule & symbol(LexerToken, LexerCategory.number) >> count
    check first(rule) == {LexerCategory.number}

  test "alternatives":
    check first(number | text) == {LexerCategory.number, LexerCategory.text}
    check first((number & text) | (text & number)) == {LexerCategory.number, LexerCategory.text}
