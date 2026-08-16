///|
struct ObserveContext {
  mut calls : Int
} derive(Eq, Debug)

///|
test "workflow exposes progress and can be reused" {
  let context = { calls: 0 }
  let workflow = @workflow.Workflow::new("reusable", context)
  workflow.add_step("one", fn(c) {
    c.calls = c.calls + 1
    true
  })
  workflow.add_step("two", fn(c) {
    c.calls = c.calls + 1
    true
  })
  inspect(workflow.get_name(), content="reusable")
  inspect(workflow.step_count(), content="2")
  inspect(workflow.current_step(), content="0")
  inspect(workflow.current_retries(), content="0")
  debug_inspect(workflow.step(), content="Running")
  inspect(workflow.current_step(), content="1")
  debug_inspect(workflow.step(), content="Success")
  inspect(workflow.current_step(), content="2")
  inspect(context.calls, content="2")
  workflow.reset()
  debug_inspect(workflow.get_status(), content="Pending")
  inspect(workflow.current_step(), content="0")
  debug_inspect(workflow.run_all(), content="Success")
  inspect(context.calls, content="4")
}

///|
test "workflow retry counters are observable before failure" {
  let context = { calls: 0 }
  let workflow = @workflow.Workflow::new("retry", context)
  workflow.add_step(
    "unstable",
    fn(c) {
      c.calls = c.calls + 1
      false
    },
    max_retries=2,
  )
  debug_inspect(workflow.step(), content="Running")
  inspect(workflow.current_retries(), content="1")
  debug_inspect(workflow.step(), content="Running")
  inspect(workflow.current_retries(), content="2")
  debug_inspect(
    workflow.step(),
    content="Failed(\"Step failed after 2 retries: unstable\")",
  )
  inspect(context.calls, content="3")
}
