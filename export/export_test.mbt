///|
enum TestState {
  Idle
  Active
  Done
} derive(Eq, Debug)

///|
enum TestEvent {
  Start
  Finish
} derive(Eq, Debug)

///|
struct TestContext {
  val : Int
} derive(Eq, Debug)

///|
fn state_str(s : TestState) -> String {
  match s {
    Idle => "Idle"
    Active => "Active"
    Done => "Done"
  }
}

///|
fn event_str(e : TestEvent) -> String {
  match e {
    Start => "Start"
    Finish => "Finish"
  }
}

///|
test "export hsm to mermaid and plantuml" {
  let ctx = { val: 0 }
  let hsm = @hsm.HSM::new(TestState::Idle, ctx)
  hsm.add_state(TestState::Active, initial_child=TestState::Idle)
  hsm.add_state(TestState::Idle, parent=TestState::Active)
  hsm.add_state(TestState::Done)

  hsm.add_transition(TestState::Idle, TestEvent::Start, TestState::Active)
  hsm.add_transition(TestState::Active, TestEvent::Finish, TestState::Done)

  let m_out = @export.export_hsm_mermaid(hsm, state_str, event_str)
  debug_inspect(
    m_out,
    content=(
      #|"stateDiagram-v2\n  [*] --> Idle\n  state Active {\n    [*] --> Idle\n  }\n  Idle --> Active : Start\n  Active --> Done : Finish\n"
    ),
  )

  let p_out = @export.export_hsm_plantuml(hsm, state_str, event_str)
  debug_inspect(
    p_out,
    content=(
      #|"@startuml\n[*] --> Idle\nstate Active {\n  [*] --> Idle\n}\nIdle --> Active : Start\nActive --> Done : Finish\n@enduml\n"
    ),
  )
}

///|
test "export workflow to mermaid" {
  let ctx = { val: 0 }
  let wf = @workflow.Workflow::new("ETL-Pipeline", ctx)
  wf.add_step("Extract", fn(_c) { true }, max_retries=3)
  wf.add_step("Transform", fn(_c) { true })
  wf.add_step("Load", fn(_c) { true }, max_retries=1)

  let wf_out = @export.export_workflow_mermaid(wf)
  debug_inspect(
    wf_out,
    content=(
      #|"flowchart TD\n  Start([Start: ETL-Pipeline]) --> Step0\n  Step0[Extract] -->|Success| Step1\n  Step0 -.->|Retry (3 max)| Step0\n  Step0 -->|Fail| Failed([Failed])\n  Step1[Transform] -->|Success| Step2\n  Step1 -->|Fail| Failed([Failed])\n  Step2[Load] -->|Success| Success([Success])\n  Step2 -.->|Retry (1 max)| Step2\n  Step2 -->|Fail| Failed([Failed])\n"
    ),
  )
}
