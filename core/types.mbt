///|
/// Represents a state transition rule in the finite state machine.
pub(all) struct Transition[S, E, C] {
  from_state : S
  event : E
  to_state : S
  cond : ((C, E) -> Bool)?
  action : ((C, E) -> Unit)?
}

///|
/// Configuration for state lifecycle hooks (entry and exit actions).
pub(all) struct StateConfig[C] {
  on_entry : ((C) -> Unit)?
  on_exit : ((C) -> Unit)?
}

///|
/// The core Finite State Machine engine holding current state, context, and transition rules.
pub(all) struct Machine[S, E, C] {
  mut current_state : S
  mut context : C
  transitions : Array[Transition[S, E, C]]
  state_configs : Array[(S, StateConfig[C])]
  mut history : Array[S]
}
