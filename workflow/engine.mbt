///|
/// Create a new workflow pipeline with a given name and initial context.
pub fn[C] Workflow::new(name : String, context : C) -> Workflow[C] {
  {
    name,
    steps: [],
    current_step_index: 0,
    status: StepStatus::Pending,
    retries_current: 0,
    context,
  }
}

///|
/// Add an execution step to the workflow pipeline.
pub fn[C] Workflow::add_step(
  self : Workflow[C],
  name : String,
  action : (C) -> Bool,
  max_retries? : Int = 0,
  on_failure? : (C, String) -> Unit,
) -> Unit {
  // Negative retry counts are not meaningful. Clamp them at the boundary so
  // a caller cannot create a step with a negative retry budget.
  let retries = if max_retries < 0 { 0 } else { max_retries }
  self.steps.push({ name, action, max_retries: retries, on_failure })
}

///|
/// Get the current overall status of the workflow.
pub fn[C] Workflow::get_status(self : Workflow[C]) -> StepStatus {
  self.status
}

///|
/// Get the context data of the workflow.
pub fn[C] Workflow::get_context(self : Workflow[C]) -> C {
  self.context
}

///|
/// Reset execution state while preserving the configured steps and context.
/// This is useful when a long-lived runner processes repeated jobs.
pub fn[C] Workflow::reset(self : Workflow[C]) -> Unit {
  self.current_step_index = 0
  self.status = StepStatus::Pending
  self.retries_current = 0
}

///|
/// Return the zero-based index of the next step to execute.
pub fn[C] Workflow::current_step(self : Workflow[C]) -> Int {
  self.current_step_index
}

///|
/// Return the number of attempts already spent on the current step.
pub fn[C] Workflow::current_retries(self : Workflow[C]) -> Int {
  self.retries_current
}

///|
/// Return the configured workflow name.
pub fn[C] Workflow::get_name(self : Workflow[C]) -> String {
  self.name
}

///|
/// Return the number of configured steps.
pub fn[C] Workflow::step_count(self : Workflow[C]) -> Int {
  self.steps.length()
}

///|
/// Return the name of the next pending step, or an empty string at terminal state.
pub fn[C] Workflow::pending_step_name(self : Workflow[C]) -> String {
  if self.is_complete() || self.current_step_index >= self.steps.length() {
    ""
  } else {
    self.steps[self.current_step_index].name
  }
}

///|
/// Return how many configured steps remain before terminal success.
pub fn[C] Workflow::remaining_steps(self : Workflow[C]) -> Int {
  if self.current_step_index >= self.steps.length() {
    0
  } else {
    self.steps.length() - self.current_step_index
  }
}

///|
/// Return the number of additional retries available for the pending step.
pub fn[C] Workflow::retry_budget(self : Workflow[C]) -> Int {
  if self.current_step_index >= self.steps.length() {
    0
  } else {
    let step = self.steps[self.current_step_index]
    let budget = step.max_retries - self.retries_current
    if budget < 0 {
      0
    } else {
      budget
    }
  }
}

///|
/// Return whether the workflow reached a terminal status.
pub fn[C] Workflow::is_complete(self : Workflow[C]) -> Bool {
  self.status == StepStatus::Success || self.status is StepStatus::Failed(_)
}

///|
/// Execute at most limit steps, allowing cooperative hosts to interleave work.
pub fn[C] Workflow::run_steps(self : Workflow[C], limit : Int) -> StepStatus {
  if limit <= 0 {
    return self.status
  }
  let mut executed = 0
  while executed < limit && !self.is_complete() {
    ignore(self.step())
    executed = executed + 1
  }
  self.status
}

///|
/// Skip the pending step and mark it successful without invoking its action.
pub fn[C] Workflow::skip_current(self : Workflow[C]) -> Bool {
  if self.is_complete() || self.current_step_index >= self.steps.length() {
    return false
  }
  self.current_step_index = self.current_step_index + 1
  self.retries_current = 0
  if self.current_step_index >= self.steps.length() {
    self.status = StepStatus::Success
  } else {
    self.status = StepStatus::Pending
  }
  true
}

///|
/// Execute a single step in the workflow pipeline.
/// Returns the updated workflow status.
pub fn[C] Workflow::step(self : Workflow[C]) -> StepStatus {
  if self.status == StepStatus::Success || self.status is StepStatus::Failed(_) {
    return self.status
  }
  if self.current_step_index >= self.steps.length() {
    self.status = StepStatus::Success
    return self.status
  }

  self.status = StepStatus::Running
  let st = self.steps[self.current_step_index]
  let success = (st.action)(self.context)

  if success {
    self.current_step_index = self.current_step_index + 1
    self.retries_current = 0
    if self.current_step_index >= self.steps.length() {
      self.status = StepStatus::Success
    }
  } else if self.retries_current < st.max_retries {
    self.retries_current = self.retries_current + 1
  } else {
    let err_msg = "Step failed after " +
      self.retries_current.to_string() +
      " retries: " +
      st.name
    match st.on_failure {
      Some(f) => f(self.context, err_msg)
      None => ()
    }
    self.status = StepStatus::Failed(err_msg)
  }
  self.status
}

///|
/// Run all remaining steps in the workflow pipeline until completion or failure.
pub fn[C] Workflow::run_all(self : Workflow[C]) -> StepStatus {
  while true {
    let s = self.step()
    if s == StepStatus::Success || s is StepStatus::Failed(_) {
      break
    }
  }
  self.status
}

///|
/// Add a conditional step that only executes if the predicate returns true.
/// Otherwise, it skips the step and immediately succeeds.
pub fn[C] Workflow::add_conditional_step(
  self : Workflow[C],
  name : String,
  predicate : (C) -> Bool,
  action : (C) -> Bool,
  max_retries? : Int = 0,
  on_failure? : (C, String) -> Unit,
) -> Unit {
  let act = fn(c) { if predicate(c) { action(c) } else { true } }
  match on_failure {
    Some(f) => self.add_step(name, act, max_retries~, on_failure=f)
    None => self.add_step(name, act, max_retries~)
  }
}

///|
/// Add a subworkflow as a single step. The subworkflow is run to completion.
pub fn[C] Workflow::add_subworkflow(
  self : Workflow[C],
  name : String,
  sub : Workflow[C],
) -> Unit {
  self.add_step(
    name,
    fn(_c) {
      match sub.run_all() {
        StepStatus::Success => true
        StepStatus::Failed(_) => false
        _ => false
      }
    },
    max_retries=0,
    on_failure=fn(c, err) {
      // Just propagate the failure name
      let _ = (c, err) // suppress unused
    },
  )
}
