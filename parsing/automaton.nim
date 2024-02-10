import ./input

type
  Automaton*[Token] = ref object
    input*: Input[Token]
    todo: seq[proc()]

proc new*[Token](_: type Automaton, input: Input[Token]): Automaton[Token] =
  Automaton[Token](input: input)

proc add*(automaton: Automaton, step: proc()) =
  automaton.todo.add(step)

proc run*(automaton: Automaton) =
  while automaton.todo.len > 0:
    let step = automaton.todo.pop()
    step()
