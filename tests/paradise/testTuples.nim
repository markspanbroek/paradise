import std/unittest
import paradise/tuples

suite "tuples":

  let empty = default tuple[]

  test "concatenates tuples":
    check empty && empty == empty
    check ('a',) && empty == ('a',)
    check empty && ('a',) == ('a',)
    check ('a',) && ('b',) == ('a', 'b')
    check ('a', 'b') && ('c',) == ('a', 'b', 'c')
    check ('a', 'b', 'c') && ('d', 'e') == ('a', 'b', 'c', 'd', 'e')

  test "concatenates tuples with regular types":
    check empty && 'a' == ('a',)
    check ('a',) && 'b' == ('a', 'b')

  test "concatenates tuple types":
    check tuple[] && tuple[] is tuple[]
    check (char,) && tuple[] is (char,)
    check tuple[] && (char,) is (char,)
    check (char,) && (int,) is (char, int)
    check (char, int) && (bool,) is (char, int, bool)
    check (char, int, bool) && (string, void) is (char, int, bool, string, void)
    check (char, char) && seq[(char, char)] is (char, char, seq[(char, char)])

  test "concatenates tuples types with regular types":
    check tuple[] && char is (char,)
    check (char,) && int is (char, int)
