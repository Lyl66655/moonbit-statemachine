///|
/// Severity of a static configuration diagnostic.
pub(all) enum Severity {
  Info
  Warning
  Error
} derive(Eq, Debug)

///|
/// A single actionable diagnostic emitted by a configuration inspection.
pub(all) struct Diagnostic {
  code : String
  severity : Severity
  subject : String
  message : String
  suggestion : String
} derive(Eq, Debug)

///|
/// Result of validating a state machine, HSM, or workflow configuration.
pub(all) struct Report {
  name : String
  diagnostics : Array[Diagnostic]
  mut checked_items : Int
}

///|
pub fn Diagnostic::new(
  code : String,
  severity : Severity,
  subject : String,
  message : String,
  suggestion : String,
) -> Diagnostic {
  { code, severity, subject, message, suggestion }
}

///|
pub fn Report::new(name : String) -> Report {
  { name, diagnostics: [], checked_items: 0 }
}

///|
pub fn Report::add(self : Report, diagnostic : Diagnostic) -> Unit {
  self.diagnostics.push(diagnostic)
}

///|
pub fn Report::name(self : Report) -> String {
  self.name
}

///|
pub fn Report::diagnostics(self : Report) -> Array[Diagnostic] {
  self.diagnostics
}

///|
pub fn Report::checked_items(self : Report) -> Int {
  self.checked_items
}

///|
pub fn Report::error_count(self : Report) -> Int {
  let mut count = 0
  for item in self.diagnostics {
    if item.severity == Severity::Error {
      count = count + 1
    }
  }
  count
}

///|
pub fn Report::warning_count(self : Report) -> Int {
  let mut count = 0
  for item in self.diagnostics {
    if item.severity == Severity::Warning {
      count = count + 1
    }
  }
  count
}

///|
pub fn Report::is_clean(self : Report) -> Bool {
  self.error_count() == 0
}

///|
pub fn Report::summary(self : Report) -> String {
  self.name +
  ": " +
  self.checked_items.to_string() +
  " checked, " +
  self.error_count().to_string() +
  " errors, " +
  self.warning_count().to_string() +
  " warnings"
}

///|
fn missing_transition(subject : String) -> Diagnostic {
  Diagnostic::new(
    "FSM001",
    Severity::Warning,
    subject,
    "No transition is registered for this state/event combination.",
    "Add an explicit transition or document that the event is intentionally ignored.",
  )
}

///|
fn invalid_retry(subject : String) -> Diagnostic {
  Diagnostic::new(
    "WF001",
    Severity::Error,
    subject,
    "A retry policy cannot be negative.",
    "Use zero for a single attempt or a positive retry count.",
  )
}

///|
fn empty_workflow(subject : String) -> Diagnostic {
  Diagnostic::new(
    "WF002",
    Severity::Warning,
    subject,
    "The workflow contains no executable steps.",
    "Add at least one step or keep the empty workflow only as an intentional no-op.",
  )
}
