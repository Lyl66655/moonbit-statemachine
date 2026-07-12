///|
pub fn init_demo() -> Unit {
  let _ = @workflow.Workflow::new("demo", ())
  let _ : @timer.Scheduler[Int] = @timer.Scheduler::new()
  let _ = @export.export_workflow_mermaid(@workflow.Workflow::new("demo", ()))
}
