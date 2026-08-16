///|
pub fn init_demo() -> Unit {
  println("[Agent] Task initialized.")
  let workflow = @workflow.Workflow::new("AI-Agent-Demo", ())
  workflow.add_step("Planning", fn(_c) {
    println("[Agent] Planning steps...")
    true
  })
  workflow.add_step("Execute", fn(_c) {
    println("[Agent] Step 1 executed.")
    true
  })
  let _ : @timer.Scheduler[Int] = @timer.Scheduler::new()
  let diagram = @export.export_workflow_mermaid(workflow)
  let _ = diagram.length()
  match workflow.run_all() {
    @workflow.StepStatus::Success =>
      println("[Agent] Workflow completed successfully.")
    @workflow.StepStatus::Failed(message) =>
      println("[Agent] Workflow failed: " + message)
    _ => println("[Agent] Workflow is still running.")
  }
}
