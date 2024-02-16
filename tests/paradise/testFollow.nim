import std/unittest
import pkg/questionable
import paradise/grammar
import paradise/LL1
import paradise/recursion

suite "follow set":

  test "symbols":
    check symbol('a').follow.len == 0
    check symbol('!').follow.len == 0

  test "character sets":
    check symbol({'a'..'z'}).follow.len == 0
    check symbol({'0'..'9'}).follow.len == 0

  test "end of input":
    check finish().follow.len == 0

  test "concatenation":
    let a = symbol('a')
    let b = symbol('b')
    let concatenation = (a & b)
    concatenation.update()
    check a.follow == {'b'}
    check b.follow.len == 0

  test "nested concatenation":
    let a = symbol('a')
    let b = symbol('b')
    let c = symbol('c')
    let d = symbol('d')
    let e = symbol('e')
    let concatenation = (a & b & c & d & e)
    concatenation.update()
    check a.follow == {'b'}
    check b.follow == {'c'}
    check c.follow == {'d'}
    check d.follow == {'e'}
    check e.follow.len == 0

  test "conversion":
    proc charToInt(c: char): int = c.int - '0'.int
    let one = symbol('1')
    let two = symbol('2')
    let oneInt = one >> charToInt
    let twoInt = two >> charToInt
    let concatenation = (oneInt & twoInt)
    concatenation.update()
    check one.follow == {'2'}
    check two.follow.len == 0
    check oneInt.follow == {'2'}
    check twoInt.follow.len == 0

  test "optional":
    let a = symbol('a')
    let b = symbol('b')
    let c = symbol('c')
    let maybe = ?b
    let concatenation = (a & maybe & c)
    concatenation.update()
    check a.follow == {'b', 'c'}
    check b.follow == {'c'}
    check c.follow.len == 0
    check maybe.follow == {'c'}

  test "optional concatenation":
    let a = symbol('a')
    let b = symbol('b')
    let c = symbol('c')
    let optional = ?(a & b)
    let concatenation = (optional & c)
    concatenation.update()
    check a.follow == {'b'}
    check b.follow == {'c'}
    check c.follow.len == 0
    check optional.follow == {'c'}

  test "repetition *":
    let a = symbol('a')
    let b = symbol('b')
    let c = symbol('c')
    let repetition = *b
    let concatenation = (a & repetition & c)
    concatenation.update()
    check a.follow == {'b', 'c'}
    check b.follow == {'b', 'c'}
    check c.follow.len == 0
    check repetition.follow == {'c'}

  test "repetition +":
    let a = symbol('a')
    let b = symbol('b')
    let c = symbol('c')
    let repetition = +b
    let concatenation = (a & repetition & c)
    concatenation.update()
    check a.follow == {'b'}
    check b.follow == {'b','c'}
    check c.follow.len == 0
    check repetition.follow == {'c'}

  test "recursive rules":
    let x = recursive int
    proc length(parsed: ?(int, char)): int = (parsed.?[0] |? 0) + 1
    define x: ?(x & symbol('x')) >> length
    update(x)
    check x.follow == {'x'}

  test "alternatives":
    let a = symbol('a')
    let b = symbol('b')
    let c = symbol('c')
    let alternatives = a | b
    let concatenation = (alternatives & c)
    concatenation.update()
    check a.follow == {'c'}
    check b.follow == {'c'}
    check c.follow.len == 0
    check alternatives.follow == {'c'}
