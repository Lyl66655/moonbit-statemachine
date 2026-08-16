///|
test "workflow run_steps supports cooperative scheduling" {
  let context = { calls: 0 }
  let workflow = @workflow.Workflow::new("cooperative", context)
  workflow.add_step("a", fn(c) {
    c.calls += 1
    true
  })
  workflow.add_step("b", fn(c) {
    c.calls += 1
    true
  })
  workflow.add_step("c", fn(c) {
    c.calls += 1
    true
  })
  debug_inspect(workflow.run_steps(1), content="Running")
  inspect(workflow.current_step(), content="1")
  inspect(context.calls, content="1")
  debug_inspect(workflow.run_steps(1), content="Running")
  debug_inspect(workflow.run_steps(10), content="Success")
  inspect(context.calls, content="3")
}

///|
test "workflow skip does not invoke the skipped action" {
  let context = { calls: 0 }
  let workflow = @workflow.Workflow::new("skip", context)
  workflow.add_step("optional", fn(c) {
    c.calls += 1
    true
  })
  workflow.add_step("required", fn(c) {
    c.calls += 1
    true
  })
  inspect(workflow.skip_current(), content="true")
  inspect(context.calls, content="0")
  debug_inspect(workflow.run_all(), content="Success")
  inspect(context.calls, content="1")
  inspect(workflow.skip_current(), content="false")
}
