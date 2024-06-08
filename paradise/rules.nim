import std/macros
import ./basics
import ./recursion

macro rule*(name: untyped{ident}, definition): untyped =
  let nameLiteral = newLit($name)
  quote do:
    bind basics.items
    let `name` = recursive(`nameLiteral`, typeof(`definition`).Token, typeof(!`definition`.output))
    define `name`: `definition`
