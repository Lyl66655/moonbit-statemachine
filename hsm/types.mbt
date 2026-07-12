///|
/// Represents hierarchical metadata for a state, including optional parent and initial child state.
pub(all) struct HState[S] {
  state : S
  parent : S?
  initial_child : S?
}

///|
/// Hierarchical State Machine (Statechart) engine with event bubbling and parent-child state resolution.
pub(all) struct HSM[S, E, C] {
  mut current_state : S
  mut context : C
  hierarchy : Array[HState[S]]
  transitions : Array[@core.Transition[S, E, C]]
  state_configs : Array[(S, @core.StateConfig[C])]
  mut history : Array[S]
}
