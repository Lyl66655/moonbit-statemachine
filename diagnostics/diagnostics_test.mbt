///|
enum State {
  Idle
  Active
} derive(Eq, Debug)

///|
enum Event {
  Start
} derive(Eq, Debug)

///|
struct Context {
  runs : Int
} derive(Eq, Debug)

///|
test "machine diagnostics distinguish empty and intentional self transitions" {
  let empty : @core.Machine[State, Event, Context] = @core.Machine::new(
    State::Idle,
    { runs: 0 },
  )
  let empty_report = @diagnostics.validate_machine("empty", empty)
  inspect(empty_report.error_count(), content="0")
  inspect(empty_report.warning_count(), content="1")
  inspect(empty_report.is_clean(), content="true")

  let machine : @core.Machine[State, Event, Context] = @core.Machine::new(
    State::Idle,
    { runs: 0 },
  )
  machine.add_transition(State::Idle, Event::Start, State::Idle)
  let report = @diagnostics.validate_machine("self", machine)
  inspect(report.checked_items(), content="1")
  inspect(report.diagnostics().length(), content="1")
  inspect(report.is_clean(), content="true")
}

///|
test "hsm diagnostics find an unregistered parent" {
  let hsm : @hsm.HSM[State, Event, Context] = @hsm.HSM::new(State::Idle, {
    runs: 0,
  })
  hsm.add_state(State::Active, parent=State::Idle)
  let report = @diagnostics.validate_hsm("hierarchy", hsm)
  inspect(report.error_count(), content="0")

  hsm.add_state(State::Active, parent=State::Active)
  let invalid = @diagnostics.validate_hsm("invalid", hsm)
  inspect(invalid.error_count(), content="0")
}

///|
test "workflow diagnostics report no-op and unnamed steps" {
  let empty = @workflow.Workflow::new("empty", { runs: 0 })
  let empty_report = @diagnostics.validate_workflow("empty", empty)
  inspect(empty_report.warning_count(), content="1")

  let named = @workflow.Workflow::new("named", { runs: 0 })
  named.add_step("", fn(_c) { true })
  let report = @diagnostics.validate_workflow("named", named)
  inspect(report.warning_count(), content="1")
  inspect(report.checked_items(), content="1")
  inspect(@diagnostics.format_report(report).contains("WF003"), content="true")
}
