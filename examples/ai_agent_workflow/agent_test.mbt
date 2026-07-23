///|
struct AgentContext {
  mut code_written : Bool
  mut tests_passed : Bool
  mut retries : Int
  log : Array[String]
} derive(Eq, Debug)

///|
test "ai agent autonomous coding pipeline" {
  let ctx = { code_written: false, tests_passed: false, retries: 0, log: [] }
  let wf = @workflow.Workflow::new("Antigravity-Agent-Pipeline", ctx)

  wf.add_step("Research & Plan", fn(c) {
    c.log.push("[1] Analyzed codebase and created implementation plan.")
    true
  })

  wf.add_step(
    "Write Implementation",
    fn(c) {
      if c.retries == 0 {
        c.retries = c.retries + 1
        c.log.push("[2] Attempt 1: Syntax error during compilation.")
        false
      } else {
        c.code_written = true
        c.log.push("[2] Attempt 2: Code compiled successfully!")
        true
      }
    },
    max_retries=2,
  )

  wf.add_step("Run Automated Tests", fn(c) {
    if c.code_written {
      c.tests_passed = true
      c.log.push("[3] All 8 unit tests passed with 0 warnings.")
      true
    } else {
      false
    }
  })

  wf.add_step("Self-Review & Doc", fn(c) {
    c.log.push("[4] Verified OSC 2026 guidelines and generated documentation.")
    true
  })

  let status = wf.run_all()
  debug_inspect(status, content="Success")
  debug_inspect(
    ctx.log,
    content=(
      #|[
      #|  "[1] Analyzed codebase and created implementation plan.",
      #|  "[2] Attempt 1: Syntax error during compilation.",
      #|  "[2] Attempt 2: Code compiled successfully!",
      #|  "[3] All 8 unit tests passed with 0 warnings.",
      #|  "[4] Verified OSC 2026 guidelines and generated documentation.",
      #|]
    ),
  )

  let diagram = @export.export_workflow_mermaid(wf)
  debug_inspect(
    diagram,
    content=(
      #|"flowchart TD\n  Start([Start: Antigravity-Agent-Pipeline]) --> Step0\n  Step0[Research & Plan] -->|Success| Step1\n  Step0 -->|Fail| Failed([Failed])\n  Step1[Write Implementation] -->|Success| Step2\n  Step1 -.->|Retry (2 max)| Step1\n  Step1 -->|Fail| Failed([Failed])\n  Step2[Run Automated Tests] -->|Success| Step3\n  Step2 -->|Fail| Failed([Failed])\n  Step3[Self-Review & Doc] -->|Success| Success([Success])\n  Step3 -->|Fail| Failed([Failed])\n"
    ),
  )

  let sched = @timer.Scheduler::new()
  let _ = sched.schedule_after(30000L, "Timeout")
  debug_inspect(sched.get_time(), content="0")
}
