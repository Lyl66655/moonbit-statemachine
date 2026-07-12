///|
enum PlayerState {
  Alive
  Standing
  Running
  Dead
} derive(Eq, Debug)

///|
enum PlayerEvent {
  Move
  Stop
  FatalHit
  Respawn
} derive(Eq, Debug)

///|
struct PlayerContext {
  health : Int
  log : Array[String]
} derive(Eq, Debug)

///|
test "hsm event bubbling and hierarchy" {
  let ctx = { health: 100, log: [] }
  let hsm = @hsm.HSM::new(PlayerState::Standing, ctx)
  hsm.add_state(PlayerState::Alive, initial_child=PlayerState::Standing)
  hsm.add_state(PlayerState::Standing, parent=PlayerState::Alive)
  hsm.add_state(PlayerState::Running, parent=PlayerState::Alive)
  hsm.add_state(PlayerState::Dead)

  hsm.on_state(
    PlayerState::Alive,
    on_entry=fn(c) { c.log.push("enter_alive") },
    on_exit=fn(c) { c.log.push("exit_alive") },
  )
  hsm.on_state(
    PlayerState::Standing,
    on_entry=fn(c) { c.log.push("enter_standing") },
    on_exit=fn(c) { c.log.push("exit_standing") },
  )
  hsm.on_state(
    PlayerState::Running,
    on_entry=fn(c) { c.log.push("enter_running") },
    on_exit=fn(c) { c.log.push("exit_running") },
  )

  hsm.add_transition(PlayerState::Standing, PlayerEvent::Move, PlayerState::Running)
  hsm.add_transition(PlayerState::Running, PlayerEvent::Stop, PlayerState::Standing)
  hsm.add_transition(PlayerState::Alive, PlayerEvent::FatalHit, PlayerState::Dead)
  hsm.add_transition(PlayerState::Dead, PlayerEvent::Respawn, PlayerState::Standing)

  let res1 = hsm.send(PlayerEvent::Move)
  inspect(res1, content="true")
  debug_inspect(hsm.get_state(), content="Running")
  
  let res2 = hsm.send(PlayerEvent::FatalHit)
  inspect(res2, content="true")
  debug_inspect(hsm.get_state(), content="Dead")
  debug_inspect(ctx.log, content=(
    #|["exit_standing", "enter_running", "exit_running", "exit_alive"]
  ))
  
  let res3 = hsm.send(PlayerEvent::Respawn)
  inspect(res3, content="true")
  debug_inspect(hsm.get_state(), content="Standing")
}
