import std/typetraits
import std/macros

macro concatenate(a: tuple, b: tuple, lenA, lenB: static int): auto =
  let c = newNimNode(nnkTupleConstr)
  for i in 0..<lenA:
    c.add quote do:
      `a`[`i`]
  for i in 0..<lenB:
    c.add quote do:
      `b`[`i`]
  c

func `&`*[A: tuple, B: tuple](a: A, b: B): auto =
  concatenate(a, b, tupleLen(a), tupleLen(b))

func `&`*[A: tuple, B: not tuple](a: A, b: B): auto =
  concatenate(a, (b,), tupleLen(a), 1)

template `&`*(A: type tuple, B: type): auto =
  typeof(A.default & B.default)
