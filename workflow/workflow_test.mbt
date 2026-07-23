///|
struct DeployContext {
  mut attempts : Int
  mut deployed : Bool
  log : Array[String]
} derive(Eq, Debug)

///|
test "workflow execution with retry policy" {
  let ctx = { attempts: 0, deployed: false, log: [] }
  let wf = @workflow.Workflow::new("AI-Agent-Deploy", ctx)

  wf.add_step("Build Project", fn(c) {
    c.log.push("built")
    true
  })

  wf.add_step(
    "Run Tests",
    fn(c) {
      c.attempts = c.attempts + 1
      if c.attempts < 3 {
        c.log.push("test_failed_try_" + c.attempts.to_string())
        false
      } else {
        c.log.push("test_passed")
        true
      }
    },
    max_retries=2,
  )

  wf.add_step("Deploy to Server", fn(c) {
    c.deployed = true
    c.log.push("deployed")
    true
  })

  let status = wf.run_all()
  debug_inspect(status, content="Success")
  debug_inspect(ctx.deployed, content="true")
  debug_inspect(ctx.attempts, content="3")
  debug_inspect(
    ctx.log,
    content=(
      #|[
      #|  "built",
      #|  "test_failed_try_1",
      #|  "test_failed_try_2",
      #|  "test_passed",
      #|  "deployed",
      #|]
    ),
  )
}

///|
test "workflow failure after retries exhausted" {
  let ctx = { attempts: 0, deployed: false, log: [] }
  let wf = @workflow.Workflow::new("Failing-Workflow", ctx)

  wf.add_step(
    "Always Fails",
    fn(c) {
      c.attempts = c.attempts + 1
      false
    },
    max_retries=1,
    on_failure=fn(c, err) { c.log.push("error_hook: " + err) },
  )

  let status = wf.run_all()
  debug_inspect(
    status,
    content="Failed(\"Step failed after 1 retries: Always Fails\")",
  )
  debug_inspect(ctx.attempts, content="2")
  debug_inspect(
    ctx.log,
    content="[\"error_hook: Step failed after 1 retries: Always Fails\"]",
  )
}

///|
test "workflow abnormal input and boundaries" {
  let ctx = { attempts: 0, deployed: false, log: [] }
  let wf = @workflow.Workflow::new("Empty-Workflow", ctx)

  // Running an empty workflow should succeed trivially
  let status1 = wf.run_all()
  debug_inspect(status1, content="Success")

  // Step that attempts to crash or behaves weirdly (simulated by returning false immediately)
  let wf2 = @workflow.Workflow::new("Bad-Workflow", ctx)
  wf2.add_step("Bad Step", fn(_c) { false }, max_retries=0)

  let status2 = wf2.run_all()
  debug_inspect(
    status2,
    content="Failed(\"Step failed after 0 retries: Bad Step\")",
  )
}
