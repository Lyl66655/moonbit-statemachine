///|
/// Create a new Hierarchical State Machine.
pub fn[S, E, C] HSM::new(initial : S, context : C) -> HSM[S, E, C] {
  {
    current_state: initial,
    context,
    hierarchy: [{ state: initial, parent: None, initial_child: None }],
    transitions: [],
    state_configs: [],
    history: [initial],
  }
}

///|
/// Register state hierarchy metadata (parent state and optional default initial child).
pub fn[S : Eq, E, C] HSM::add_state(
  self : HSM[S, E, C],
  state : S,
  parent? : S,
  initial_child? : S
) -> Unit {
  for i = 0; i < self.hierarchy.length(); i = i + 1 {
    if self.hierarchy[i].state == state {
      self.hierarchy[i] = { state, parent, initial_child }
      return
    }
  }
  self.hierarchy.push({ state, parent, initial_child })
}

///|
/// Get the parent state of a given state, if configured.
pub fn[S : Eq, E, C] HSM::get_parent(self : HSM[S, E, C], state : S) -> S? {
  for i = 0; i < self.hierarchy.length(); i = i + 1 {
    if self.hierarchy[i].state == state {
      return self.hierarchy[i].parent
    }
  }
  None
}

///|
/// Get the path from the given state up to the root ancestor: [state, parent, grandparent, ...].
pub fn[S : Eq, E, C] HSM::get_path_to_root(
  self : HSM[S, E, C],
  state : S
) -> Array[S] {
  let path = []
  let mut curr = Some(state)
  while curr is Some(s) {
    path.push(s)
    curr = self.get_parent(s)
  }
  path
}

///|
/// Recursively resolve the initial leaf child of a composite state.
pub fn[S : Eq, E, C] HSM::resolve_initial_leaf(
  self : HSM[S, E, C],
  state : S
) -> S {
  let mut curr = state
  while true {
    let mut found_child = false
    for i = 0; i < self.hierarchy.length(); i = i + 1 {
      if self.hierarchy[i].state == curr {
        match self.hierarchy[i].initial_child {
          Some(child) => {
            curr = child
            found_child = true
          }
          None => ()
        }
        break
      }
    }
    if !found_child {
      break
    }
  }
  curr
}

///|
/// Register a transition rule for the hierarchical machine.
pub fn[S, E, C] HSM::add_transition(
  self : HSM[S, E, C],
  from_state : S,
  event : E,
  to_state : S,
  cond? : (C, E) -> Bool,
  action? : (C, E) -> Unit
) -> Unit {
  self.transitions.push(
    { from_state, event, to_state, cond, action }
  )
}

///|
/// Register lifecycle hooks (on_entry / on_exit) for a specific state.
pub fn[S : Eq, E, C] HSM::on_state(
  self : HSM[S, E, C],
  state : S,
  on_entry? : (C) -> Unit,
  on_exit? : (C) -> Unit
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
/// Helper to find state config.
fn[S : Eq, E, C] HSM::find_config(
  self : HSM[S, E, C],
  state : S
) -> @core.StateConfig[C]? {
  for i = 0; i < self.state_configs.length(); i = i + 1 {
    if self.state_configs[i].0 == state {
      return Some(self.state_configs[i].1)
    }
  }
  None
}

///|
/// Get active leaf state.
pub fn[S, E, C] HSM::get_state(self : HSM[S, E, C]) -> S {
  self.current_state
}

///|
/// Get context data.
pub fn[S, E, C] HSM::get_context(self : HSM[S, E, C]) -> C {
  self.context
}

///|
/// Get history.
pub fn[S, E, C] HSM::get_history(self : HSM[S, E, C]) -> Array[S] {
  self.history
}

///|
/// Send an event to the HSM, triggering event bubbling from current leaf state up to ancestors.
pub fn[S : Eq, E : Eq, C] HSM::send(self : HSM[S, E, C], event : E) -> Bool {
  let active_path = self.get_path_to_root(self.current_state)
  for i = 0; i < active_path.length(); i = i + 1 {
    let s = active_path[i]
    for j = 0; j < self.transitions.length(); j = j + 1 {
      let t = self.transitions[j]
      if t.from_state == s && t.event == event {
        let guard_passed = match t.cond {
          Some(g) => g(self.context, event)
          None => true
        }
        if guard_passed {
          let target_leaf = self.resolve_initial_leaf(t.to_state)
          let exit_path = active_path
          let target_path_to_root = self.get_path_to_root(target_leaf)
          
          for k = 0; k < exit_path.length(); k = k + 1 {
            let ex_st = exit_path[k]
            if !target_path_to_root.contains(ex_st) {
              match self.find_config(ex_st) {
                Some(cfg) =>
                  match cfg.on_exit {
                    Some(exit_fn) => exit_fn(self.context)
                    None => ()
                  }
                None => ()
              }
            }
          }

          match t.action {
            Some(act) => act(self.context, event)
            None => ()
          }

          self.current_state = target_leaf
          self.history.push(target_leaf)

          for k = target_path_to_root.length() - 1; k >= 0; k = k - 1 {
            let en_st = target_path_to_root[k]
            if !exit_path.contains(en_st) {
              match self.find_config(en_st) {
                Some(cfg) =>
                  match cfg.on_entry {
                    Some(entry_fn) => entry_fn(self.context)
                    None => ()
                  }
                None => ()
              }
            }
          }
          return true
        }
      }
    }
  }
  false
}
