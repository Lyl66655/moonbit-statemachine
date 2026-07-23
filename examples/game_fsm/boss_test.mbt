///|
enum BossState {
  Peaceful
  Patrol
  Combat
  Chase
  Attack
  Enraged
  Defeated
} derive(Eq, Debug)

///|
enum BossEvent {
  PlayerSpotted
  PlayerInMeleeRange
  PlayerOutRange
  HealthBelowHalf
  FatalStrike
} derive(Eq, Debug)

///|
struct BossContext {
  health : Int
  mut attack_power : Int
  log : Array[String]
} derive(Eq, Debug)

///|
fn bstate_str(s : BossState) -> String {
  match s {
    Peaceful => "Peaceful"
    Patrol => "Patrol"
    Combat => "Combat"
    Chase => "Chase"
    Attack => "Attack"
    Enraged => "Enraged"
    Defeated => "Defeated"
  }
}

///|
fn bevent_str(e : BossEvent) -> String {
  match e {
    PlayerSpotted => "PlayerSpotted"
    PlayerInMeleeRange => "PlayerInMeleeRange"
    PlayerOutRange => "PlayerOutRange"
    HealthBelowHalf => "HealthBelowHalf"
    FatalStrike => "FatalStrike"
  }
}

///|
test "rpg boss battle hierarchical state machine" {
  let ctx = { health: 1000, attack_power: 50, log: [] }
  let hsm = @hsm.HSM::new(BossState::Patrol, ctx)

  hsm.add_state(BossState::Peaceful, initial_child=BossState::Patrol)
  hsm.add_state(BossState::Patrol, parent=BossState::Peaceful)
  hsm.add_state(BossState::Combat, initial_child=BossState::Chase)
  hsm.add_state(BossState::Chase, parent=BossState::Combat)
  hsm.add_state(BossState::Attack, parent=BossState::Combat)
  hsm.add_state(BossState::Enraged, parent=BossState::Combat)
  hsm.add_state(BossState::Defeated)

  hsm.on_state(
    BossState::Combat,
    on_entry=fn(c) { c.log.push("Entering Combat! Music changes.") },
    on_exit=fn(c) { c.log.push("Exiting Combat! Battle over.") },
  )
  hsm.on_state(BossState::Enraged, on_entry=fn(c) {
    c.attack_power = c.attack_power * 2
    c.log.push(
      "Boss Enraged! Attack power doubled to " + c.attack_power.to_string(),
    )
  })

  hsm.add_transition(
    BossState::Patrol,
    BossEvent::PlayerSpotted,
    BossState::Combat,
  )
  hsm.add_transition(
    BossState::Chase,
    BossEvent::PlayerInMeleeRange,
    BossState::Attack,
  )
  hsm.add_transition(
    BossState::Attack,
    BossEvent::PlayerOutRange,
    BossState::Chase,
  )
  hsm.add_transition(
    BossState::Combat,
    BossEvent::HealthBelowHalf,
    BossState::Enraged,
  )
  hsm.add_transition(
    BossState::Combat,
    BossEvent::FatalStrike,
    BossState::Defeated,
  )

  let _ = hsm.send(BossEvent::PlayerSpotted)
  debug_inspect(hsm.get_state(), content="Chase")

  let _ = hsm.send(BossEvent::PlayerInMeleeRange)
  debug_inspect(hsm.get_state(), content="Attack")

  let _ = hsm.send(BossEvent::HealthBelowHalf)
  debug_inspect(hsm.get_state(), content="Enraged")
  debug_inspect(ctx.attack_power, content="100")

  let _ = hsm.send(BossEvent::FatalStrike)
  debug_inspect(hsm.get_state(), content="Defeated")
  debug_inspect(
    ctx.log,
    content=(
      #|[
      #|  "Entering Combat! Music changes.",
      #|  "Boss Enraged! Attack power doubled to 100",
      #|  "Exiting Combat! Battle over.",
      #|]
    ),
  )

  let diagram = @export.export_hsm_mermaid(hsm, bstate_str, bevent_str)
  debug_inspect(
    diagram,
    content=(
      #|"stateDiagram-v2\n  [*] --> Defeated\n  state Peaceful {\n    [*] --> Patrol\n  }\n  state Combat {\n    [*] --> Chase\n  }\n  Patrol --> Combat : PlayerSpotted\n  Chase --> Attack : PlayerInMeleeRange\n  Attack --> Chase : PlayerOutRange\n  Combat --> Enraged : HealthBelowHalf\n  Combat --> Defeated : FatalStrike\n"
    ),
  )
}
