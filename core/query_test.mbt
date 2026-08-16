///|
enum QueryState {
  Cold
  Ready
  Running
} derive(Eq, Debug)

///|
enum QueryEvent {
  Prepare
  Run
} derive(Eq, Debug)

///|
test "machine query API is side-effect free" {
  let machine : @core.Machine[QueryState, QueryEvent, Unit] = @core.Machine::new(
    QueryState::Cold,
    (),
  )
  machine.add_transition(
    QueryState::Cold,
    QueryEvent::Prepare,
    QueryState::Ready,
  )
  machine.add_transition(
    QueryState::Ready,
    QueryEvent::Run,
    QueryState::Running,
  )
  inspect(machine.transition_count(), content="2")
  inspect(machine.can_send(QueryEvent::Prepare), content="true")
  inspect(machine.can_send(QueryEvent::Run), content="false")
  inspect(machine.get_history().length(), content="1")
  inspect(machine.send(QueryEvent::Prepare), content="true")
  inspect(machine.has_visited(QueryState::Cold), content="true")
  inspect(machine.has_visited(QueryState::Ready), content="true")
  inspect(machine.can_send(QueryEvent::Run), content="true")
}

///|
test "machine checkpoint keeps current state and removes old history" {
  let machine : @core.Machine[QueryState, QueryEvent, Unit] = @core.Machine::new(
    QueryState::Cold,
    (),
  )
  machine.add_transition(
    QueryState::Cold,
    QueryEvent::Prepare,
    QueryState::Ready,
  )
  machine.add_transition(
    QueryState::Ready,
    QueryEvent::Run,
    QueryState::Running,
  )
  ignore(machine.send(QueryEvent::Prepare))
  ignore(machine.send(QueryEvent::Run))
  machine.checkpoint()
  debug_inspect(machine.get_state(), content="Running")
  debug_inspect(machine.get_history(), content="[Running]")
  inspect(machine.has_visited(QueryState::Cold), content="false")
  inspect(machine.has_visited(QueryState::Running), content="true")
}
