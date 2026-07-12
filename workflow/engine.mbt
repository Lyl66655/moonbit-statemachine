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
  max_retries~ : Int = 0,
  on_failure? : (C, String) -> Unit
) -> Unit {
  self.steps.push({ name, action, max_retries, on_failure })
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
  } else {
    if self.retries_current < st.max_retries {
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
