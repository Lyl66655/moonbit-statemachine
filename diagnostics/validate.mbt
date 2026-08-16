///|
/// Validate a core machine's registered transition table.
pub fn[S : Eq, E, C] validate_machine(
  name : String,
  machine : @core.Machine[S, E, C],
) -> Report {
  let report = Report::new(name)
  report.checked_items = machine.transitions.length()
  if machine.transitions.length() == 0 {
    report.add(missing_transition("machine"))
  }
  for i = 0; i < machine.transitions.length(); i = i + 1 {
    let transition = machine.transitions[i]
    if transition.from_state == transition.to_state && transition.action is None {
      report.add(
        Diagnostic::new(
          "FSM002",
          Severity::Info,
          "transition_" + i.to_string(),
          "This is a self-transition without an action.",
          "Confirm that the self-transition is intentional.",
        ),
      )
    }
  }
  report
}

///|
/// Validate an HSM hierarchy for missing parents and inconsistent initial children.
pub fn[S : Eq, E, C] validate_hsm(
  name : String,
  hsm : @hsm.HSM[S, E, C],
) -> Report {
  let report = Report::new(name)
  report.checked_items = hsm.hierarchy.length()
  for i = 0; i < hsm.hierarchy.length(); i = i + 1 {
    let item = hsm.hierarchy[i]
    match item.parent {
      Some(parent) =>
        if !contains_state(hsm, parent) {
          report.add(
            Diagnostic::new(
              "HSM001",
              Severity::Error,
              "state_" + i.to_string(),
              "The configured parent is not registered in the hierarchy.",
              "Register the parent state before using it as a composite state.",
            ),
          )
        }
      None => ()
    }
    match item.initial_child {
      Some(child) =>
        if !contains_state(hsm, child) {
          report.add(
            Diagnostic::new(
              "HSM002",
              Severity::Error,
              "state_" + i.to_string(),
              "The initial child does not point back to this composite state.",
              "Set the child's parent to the composite state.",
            ),
          )
        }
      None => ()
    }
  }
  report
}

///|
/// Validate workflow step names and retry policies.
pub fn[C] validate_workflow(
  name : String,
  workflow : @workflow.Workflow[C],
) -> Report {
  let report = Report::new(name)
  report.checked_items = workflow.steps.length()
  if workflow.steps.length() == 0 {
    report.add(empty_workflow("workflow"))
  }
  for i = 0; i < workflow.steps.length(); i = i + 1 {
    let step = workflow.steps[i]
    if step.name.length() == 0 {
      report.add(
        Diagnostic::new(
          "WF003",
          Severity::Warning,
          "step_" + i.to_string(),
          "The step has an empty display name.",
          "Use a stable name so logs and failure reports are actionable.",
        ),
      )
    }
    if step.max_retries < 0 {
      report.add(invalid_retry(step.name))
    }
  }
  report
}

///|
/// Return a compact human-readable report suitable for CI logs.
pub fn format_report(report : Report) -> String {
  let mut out = report.summary() + "\n"
  for item in report.diagnostics {
    out = out +
      "[" +
      severity_name(item.severity) +
      "] " +
      item.code +
      " " +
      item.subject +
      ": " +
      item.message +
      " Suggestion: " +
      item.suggestion +
      "\n"
  }
  out
}

///|
fn severity_name(severity : Severity) -> String {
  match severity {
    Severity::Info => "info"
    Severity::Warning => "warning"
    Severity::Error => "error"
  }
}

///|
fn[S : Eq, E, C] contains_state(hsm : @hsm.HSM[S, E, C], state : S) -> Bool {
  for item in hsm.hierarchy {
    if item.state == state {
      return true
    }
  }
  false
}
