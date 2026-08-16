///|
test "workflow progress queries describe pending work" {
  let workflow = @workflow.Workflow::new("progress", ())
  workflow.add_step("first", fn(_c) { true }, max_retries=2)
  workflow.add_step("second", fn(_c) { true })
  inspect(workflow.pending_step_name(), content="first")
  inspect(workflow.remaining_steps(), content="2")
  inspect(workflow.retry_budget(), content="2")
  debug_inspect(workflow.step(), content="Running")
  inspect(workflow.pending_step_name(), content="second")
  inspect(workflow.remaining_steps(), content="1")
  debug_inspect(workflow.step(), content="Success")
  inspect(workflow.pending_step_name(), content="")
  inspect(workflow.remaining_steps(), content="0")
  inspect(workflow.retry_budget(), content="0")
}
