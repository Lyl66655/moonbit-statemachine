///|
enum TurnstileState {
  Locked
  Unlocked
} derive(Eq, Debug)

///|
enum TurnstileEvent {
  Coin
  Push
} derive(Eq, Debug)

///|
struct TurnstileContext {
  mut coins : Int
  mut entries : Int
} derive(Eq, Debug)

///|
test "turnstile basic fsm" {
  let ctx = { coins: 0, entries: 0 }
  let fsm = @core.Machine::new(TurnstileState::Locked, ctx)
  fsm.add_transition(
    TurnstileState::Locked,
    TurnstileEvent::Coin,
    TurnstileState::Unlocked,
    action=fn(c, _e) { c.coins += 1 },
  )
  fsm.add_transition(
    TurnstileState::Unlocked,
    TurnstileEvent::Push,
    TurnstileState::Locked,
    action=fn(c, _e) { c.entries += 1 },
  )
  let res1 = fsm.send(TurnstileEvent::Push)
  inspect(res1, content="false")
  debug_inspect(fsm.get_state(), content="Locked")
  let res2 = fsm.send(TurnstileEvent::Coin)
  inspect(res2, content="true")
  debug_inspect(fsm.get_state(), content="Unlocked")
  inspect(fsm.get_context().coins, content="1")
  let res3 = fsm.send(TurnstileEvent::Push)
  inspect(res3, content="true")
  debug_inspect(fsm.get_state(), content="Locked")
  inspect(fsm.get_context().entries, content="1")
}

///|
test "fsm guard condition" {
  let ctx = { coins: 0, entries: 0 }
  let fsm = @core.Machine::new(TurnstileState::Locked, ctx)
  fsm.add_transition(
    TurnstileState::Locked,
    TurnstileEvent::Coin,
    TurnstileState::Unlocked,
    cond=fn(c, _e) { c.coins < 2 },
    action=fn(c, _e) { c.coins += 1 },
  )
  fsm.add_transition(
    TurnstileState::Unlocked,
    TurnstileEvent::Push,
    TurnstileState::Locked,
  )
  ignore(fsm.send(TurnstileEvent::Coin))
  ignore(fsm.send(TurnstileEvent::Push))
  ignore(fsm.send(TurnstileEvent::Coin))
  ignore(fsm.send(TurnstileEvent::Push))
  let res = fsm.send(TurnstileEvent::Coin)
  inspect(res, content="false")
  debug_inspect(fsm.get_state(), content="Locked")
  inspect(fsm.get_context().coins, content="2")
}
