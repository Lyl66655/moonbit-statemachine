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
/// Validate an HSM hierarchy for missing parents, cycles, and inconsistent initial children.
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
        } else {
          match hsm.get_parent(child) {
            Some(parent) =>
              if parent != item.state {
                report.add(
                  Diagnostic::new(
                    "HSM002",
                    Severity::Error,
                    "state_" + i.to_string(),
                    "The initial child is registered under a different parent.",
                    "Set the child's parent to this composite state.",
                  ),
                )
              }
            None =>
              report.add(
                Diagnostic::new(
                  "HSM002",
                  Severity::Error,
                  "state_" + i.to_string(),
                  "The initial child is not registered as a child of this state.",
                  "Set the child's parent to this composite state.",
                ),
              )
          }
        }
      None => ()
    }
    if has_parent_cycle(hsm, item.state) && !has_code(report, "HSM003") {
      report.add(
        Diagnostic::new(
          "HSM003",
          Severity::Error,
          "state_" + i.to_string(),
          "The parent links contain a cycle.",
          "Choose a root state and ensure every parent chain eventually reaches it.",
        ),
      )
    }
    if has_initial_child_cycle(hsm, item.state) && !has_code(report, "HSM004") {
      report.add(
        Diagnostic::new(
          "HSM004",
          Severity::Error,
          "state_" + i.to_string(),
          "The initial-child links contain a cycle.",
          "Ensure composite states resolve to a leaf instead of referring back to an ancestor.",
        ),
      )
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

///|
fn[S : Eq, E, C] has_parent_cycle(hsm : @hsm.HSM[S, E, C], state : S) -> Bool {
  let visited = []
  let mut current = Some(state)
  while current is Some(item) {
    if visited.contains(item) {
      return true
    }
    visited.push(item)
    current = hsm.get_parent(item)
  }
  false
}

///|
fn[S : Eq, E, C] has_initial_child_cycle(
  hsm : @hsm.HSM[S, E, C],
  state : S,
) -> Bool {
  let visited = []
  let mut current = Some(state)
  while current is Some(item) {
    if visited.contains(item) {
      return true
    }
    visited.push(item)
    let mut next = None
    for entry in hsm.hierarchy {
      if entry.state == item {
        next = entry.initial_child
        break
      }
    }
    current = next
  }
  false
}

///|
fn has_code(report : Report, code : String) -> Bool {
  for diagnostic in report.diagnostics {
    if diagnostic.code == code {
      return true
    }
  }
  false
}
