# Executable Documentation for StateMachine & Workflow Engine

This file is checked by `moon check` and `moon test` to ensure all documentation examples remain valid and compile cleanly.

```mbt check
enum DocState {
  Locked
  Unlocked
} derive(Eq, Debug)

enum DocEvent {
  Coin
  Push
} derive(Eq, Debug)

struct DocContext {
  mut coins : Int
} derive(Eq, Debug)

test "executable doc quickstart example" {
  let ctx = { coins: 0 }
  let fsm = @core.Machine::new(DocState::Locked, ctx)

  fsm.add_transition(
    DocState::Locked,
    DocEvent::Coin,
    DocState::Unlocked,
    cond=fn(c, _e) { c.coins < 5 },
    action=fn(c, _e) { c.coins = c.coins + 1 },
  )

  fsm.add_transition(DocState::Unlocked, DocEvent::Push, DocState::Locked)

  let res = fsm.send(DocEvent::Coin)
  debug_inspect(res, content="true")
  debug_inspect(fsm.get_state(), content="Unlocked")
  debug_inspect(ctx.coins, content="1")
}
```
