import std/unittest
import std/sets
import pkg/questionable
import parsing/grammar
import parsing/LL1
import parsing/recursion

proc last(grammar: Grammar): auto =
  update(grammar)
  grammar.last

suite "last set":

  type CharParslet = Parslet[char, char]

  test "symbols":
    let a = symbol('a')
    let b = symbol('b')
    check last(a) == [CharParslet(a)].toHashSet
    check last(b) == [CharParslet(b)].toHashSet

  test "character sets":
    let letter = symbol({'a'..'z'})
    let number = symbol({'0'..'9'})
    check last(letter) == [CharParslet(letter)].toHashSet
    check last(number) == [CharParslet(number)].toHashSet

  test "end of input":
    let x = finish()
    check last(x) == [CharParslet(x)].toHashSet

  test "conversion":
    proc charToInt(c: char): int = c.int - '0'.int
    let one = symbol('1')
    let conversion = one.convert(charToInt)
    check last(conversion) == [
      CharParslet(conversion),
      CharParslet(one)
    ].toHashSet

  test "optional":
    let a = symbol('a')
    let optional = ?a
    check last(optional) == [
      CharParslet(optional),
      CharParslet(a)
    ].toHashSet

  test "concatenation":
    let a = symbol('a')
    let b = symbol('b')
    let concatenation = a & b
    check last(concatenation) == [
      CharParslet(concatenation),
      CharParslet(b)
    ].toHashSet

  test "concatenation of optional":
    let a = symbol('a')
    let b = symbol('b')
    let maybe = ?b
    let concatenation = a & maybe
    check last(concatenation) == [
      CharParslet(concatenation),
      CharParslet(a),
      CharParslet(maybe),
      CharParslet(b)
    ].toHashSet

  test "recursive rules":
    let a = recursive int
    let b = symbol('b')
    proc length(parsed: ?(char, int)): int = (parsed.?[1] |? 0) + 1
    define a: (?(b & a)).convert(length)
    check CharParslet(a) in last(a)
    check CharParslet(b) in last(a)

  test "alternatives":
    let a = symbol('a')
    let b = symbol('b')
    let c = symbol('c')
    let d = symbol('d')
    let ab = a & b
    let cd = c & d
    let alternatives = ab | cd
    check last(alternatives) == [
      CharParslet(alternatives),
      CharParslet(ab),
      CharParslet(cd),
      CharParslet(b),
      CharParslet(d)
    ].toHashSet
