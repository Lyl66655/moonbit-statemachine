///|
enum ControlState {
  A
  B
} derive(Eq, Debug)

///|
enum ControlEvent {
  Go
} derive(Eq, Debug)

///|
test "machine transition administration is bounded" {
  let machine : @core.Machine[ControlState, ControlEvent, Unit] = @core.Machine::new(
    ControlState::A,
    (),
  )
  machine.add_transition(ControlState::A, ControlEvent::Go, ControlState::B)
  machine.add_transition(ControlState::B, ControlEvent::Go, ControlState::A)
  inspect(machine.history_count(), content="1")
  inspect(machine.remove_transition(-1), content="false")
  inspect(machine.remove_transition(2), content="false")
  inspect(machine.remove_transition(0), content="true")
  inspect(machine.transition_count(), content="1")
  machine.clear_transitions()
  inspect(machine.transition_count(), content="0")
  inspect(machine.send(ControlEvent::Go), content="false")
}
