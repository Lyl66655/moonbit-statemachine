///|
/// Create a new finite state machine with an initial state and context.
pub fn[S, E, C] Machine::new(initial : S, context : C) -> Machine[S, E, C] {
  {
    current_state: initial,
    context,
    transitions: [],
    state_configs: [],
    history: [initial],
  }
}

///|
/// Get the current active state of the machine.
pub fn[S, E, C] Machine::get_state(self : Machine[S, E, C]) -> S {
  self.current_state
}

///|
/// Get the current context data of the machine.
pub fn[S, E, C] Machine::get_context(self : Machine[S, E, C]) -> C {
  self.context
}

///|
/// Get the state transition history (all states visited since creation or reset).
pub fn[S, E, C] Machine::get_history(self : Machine[S, E, C]) -> Array[S] {
  self.history
}

///|
/// Reset the machine to a new initial state and context, clearing history.
pub fn[S, E, C] Machine::reset(
  self : Machine[S, E, C],
  initial : S,
  context : C,
) -> Unit {
  self.current_state = initial
  self.context = context
  self.history = [initial]
}

///|
/// Register a transition rule. When `event` occurs in `from_state`, if `guard` returns true (or is None),
/// the machine transitions to `to_state` and executes `action`.
pub fn[S, E, C] Machine::add_transition(
  self : Machine[S, E, C],
  from_state : S,
  event : E,
  to_state : S,
  cond? : (C, E) -> Bool,
  action? : (C, E) -> Unit,
) -> Unit {
  self.transitions.push({ from_state, event, to_state, cond, action })
}

///|
/// Register lifecycle hooks (on_entry / on_exit) for a specific state.
pub fn[S : Eq, E, C] Machine::on_state(
  self : Machine[S, E, C],
  state : S,
  on_entry? : (C) -> Unit,
  on_exit? : (C) -> Unit,
) -> Unit {
  for i = 0; i < self.state_configs.length(); i = i + 1 {
    if self.state_configs[i].0 == state {
      self.state_configs[i] = (state, { on_entry, on_exit })
      return
    }
  }
  self.state_configs.push((state, { on_entry, on_exit }))
}

///|
/// Helper to find state config for a given state.
fn[S : Eq, E, C] Machine::find_config(
  self : Machine[S, E, C],
  state : S,
) -> StateConfig[C]? {
  for i = 0; i < self.state_configs.length(); i = i + 1 {
    if self.state_configs[i].0 == state {
      return Some(self.state_configs[i].1)
    }
  }
  None
}

///|
/// Send an event to the state machine.
/// Returns `true` if a valid transition occurred, `false` otherwise.
pub fn[S : Eq, E : Eq, C] Machine::send(
  self : Machine[S, E, C],
  event : E,
) -> Bool {
  let current = self.current_state
  for i = 0; i < self.transitions.length(); i = i + 1 {
    let t = self.transitions[i]
    if t.from_state == current && t.event == event {
      let guard_passed = match t.cond {
        Some(g) => g(self.context, event)
        None => true
      }
      if guard_passed {
        match self.find_config(current) {
          Some(cfg) =>
            match cfg.on_exit {
              Some(exit_fn) => exit_fn(self.context)
              None => ()
            }
          None => ()
        }
        match t.action {
          Some(act) => act(self.context, event)
          None => ()
        }
        self.current_state = t.to_state
        self.history.push(t.to_state)
        match self.find_config(t.to_state) {
          Some(cfg) =>
            match cfg.on_entry {
              Some(entry_fn) => entry_fn(self.context)
              None => ()
            }
          None => ()
        }
        return true
      }
    }
  }
  false
}
