import std/unittest
import std/times
import paradise

suite "performance":

  test "parser for large grammar can be constructed in reasonable time":
    proc convertLeaf(parsed: char): string =
      $parsed
    proc convertBranch(parsed: (string, string)): string =
      parsed[0] & parsed[1]
    rule leaf: symbol('x') >> convertLeaf
    rule branch0: leaf & leaf >> convertBranch
    rule branch1: branch0 & branch0 >> convertBranch
    rule branch2: branch1 & branch1 >> convertBranch
    rule branch3: branch2 & branch2 >> convertBranch
    rule branch4: branch3 & branch3 >> convertBranch
    rule branch5: branch4 & branch4 >> convertBranch
    rule branch6: branch5 & branch5 >> convertBranch
    rule branch7: branch6 & branch6 >> convertBranch
    rule branch8: branch7 & branch7 >> convertBranch
    rule branch9: branch8 & branch8 >> convertBranch
    rule branch10: branch9 & branch9 >> convertBranch
    rule branch11: branch10 & branch10 >> convertBranch
    rule branch12: branch11 & branch11 >> convertBranch
    rule branch13: branch12 & branch12 >> convertBranch
    rule branch14: branch13 & branch13 >> convertBranch
    rule branch15: branch14 & branch14 >> convertBranch
    rule branch16: branch15 & branch15 >> convertBranch
    rule branch17: branch16 & branch16 >> convertBranch
    rule branch18: branch17 & branch17 >> convertBranch
    rule branch19: branch18 & branch18 >> convertBranch
    let start = now()
    discard branch19.parser
    check (now() - start) < initDuration(milliseconds=100)
