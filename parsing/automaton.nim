import ./input

type
  Automaton*[Token] = object
    input*: Input[Token]
    todo*: seq[Step[Token]]
  Step*[Token] = proc(automaton: var Automaton[Token])

proc init*[Token](_: type Automaton, input: Input[Token]): Automaton[Token] =
  Automaton[Token](input: input)

proc run*(automaton: var Automaton) =
  while automaton.todo.len > 0:
    automaton.todo.pop()(automaton)
