///|
/// Represents the execution status of a workflow or individual step.
pub(all) enum StepStatus {
  Pending
  Running
  Success
  Failed(String)
} derive(Eq, Debug)

///|
/// A single execution step in a workflow pipeline with retry support.
pub(all) struct Step[C] {
  name : String
  action : (C) -> Bool
  max_retries : Int
  on_failure : ((C, String) -> Unit)?
}

///|
/// A sequential workflow engine that executes steps with automated retry and failure handling.
pub(all) struct Workflow[C] {
  name : String
  steps : Array[Step[C]]
  mut current_step_index : Int
  mut status : StepStatus
  mut retries_current : Int
  mut context : C
}
