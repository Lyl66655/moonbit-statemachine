///|
/// A deterministic benchmark result. It reports logical work, not machine-dependent time.
pub(all) struct BenchmarkResult {
  name : String
  operations : Int
  successes : Int
  failures : Int
  notes : String
} derive(Eq, Debug)

///|
pub fn BenchmarkResult::new(
  name : String,
  operations : Int,
  successes : Int,
  failures : Int,
  notes : String,
) -> BenchmarkResult {
  { name, operations, successes, failures, notes }
}

///|
pub fn BenchmarkResult::name(self : BenchmarkResult) -> String {
  self.name
}

///|
pub fn BenchmarkResult::operations(self : BenchmarkResult) -> Int {
  self.operations
}

///|
pub fn BenchmarkResult::successes(self : BenchmarkResult) -> Int {
  self.successes
}

///|
pub fn BenchmarkResult::failures(self : BenchmarkResult) -> Int {
  self.failures
}

///|
pub fn BenchmarkResult::summary(self : BenchmarkResult) -> String {
  self.name +
  ": operations=" +
  self.operations.to_string() +
  ", successes=" +
  self.successes.to_string() +
  ", failures=" +
  self.failures.to_string() +
  ", " +
  self.notes
}

///|
/// Aggregate several deterministic benchmark results.
pub fn summarize(results : Array[BenchmarkResult]) -> String {
  let mut operations = 0
  let mut successes = 0
  let mut failures = 0
  for result in results {
    operations = operations + result.operations
    successes = successes + result.successes
    failures = failures + result.failures
  }
  "suite: operations=" +
  operations.to_string() +
  ", successes=" +
  successes.to_string() +
  ", failures=" +
  failures.to_string() +
  ", cases=" +
  results.length().to_string()
}

///|
/// Return true when every operation in the result completed successfully.
pub fn BenchmarkResult::all_successful(self : BenchmarkResult) -> Bool {
  self.failures == 0 && self.successes >= 0 && self.operations >= self.successes
}

///|
/// Render benchmark results as a Markdown table for release notes.
pub fn markdown_report(results : Array[BenchmarkResult]) -> String {
  let mut out = "| Case | Operations | Successes | Failures | Notes |\\n"
  out = out + "| --- | ---: | ---: | ---: | --- |\\n"
  for result in results {
    out = out +
      "| " +
      result.name +
      " | " +
      result.operations.to_string() +
      " | " +
      result.successes.to_string() +
      " | " +
      result.failures.to_string() +
      " | " +
      result.notes +
      " |\\n"
  }
  out
}

///|
/// Compare two result sets by case name and return human-readable deltas.
pub fn compare(
  baseline : Array[BenchmarkResult],
  current : Array[BenchmarkResult],
) -> Array[String] {
  let changes = []
  for now in current {
    let mut found = false
    for before in baseline {
      if before.name == now.name {
        found = true
        let operation_delta = now.operations - before.operations
        let success_delta = now.successes - before.successes
        changes.push(
          now.name +
          ": operations_delta=" +
          operation_delta.to_string() +
          ", successes_delta=" +
          success_delta.to_string(),
        )
      }
    }
    if !found {
      changes.push(now.name + ": new")
    }
  }
  for before in baseline {
    let mut found = false
    for now in current {
      if before.name == now.name {
        found = true
      }
    }
    if !found {
      changes.push(before.name + ": removed")
    }
  }
  changes
}

///|
/// Check that a release benchmark suite meets a minimum logical workload.
pub fn meets_release_floor(
  results : Array[BenchmarkResult],
  minimum_operations : Int,
) -> Bool {
  let mut operations = 0
  for result in results {
    operations = operations + result.operations
    if !result.all_successful() {
      return false
    }
  }
  operations >= minimum_operations
}

///|
/// Validate that a result has internally consistent accounting.
pub fn BenchmarkResult::is_consistent(self : BenchmarkResult) -> Bool {
  self.operations >= 0 &&
  self.successes >= 0 &&
  self.failures >= 0 &&
  self.successes + self.failures <= self.operations
}

///|
/// Return all inconsistent results so a benchmark report cannot hide bad data.
pub fn inconsistent(results : Array[BenchmarkResult]) -> Array[String] {
  let invalid = []
  for result in results {
    if !result.is_consistent() {
      invalid.push(result.name)
    }
  }
  invalid
}

///|
enum ToggleState {
  Off
  On
} derive(Eq, Debug)

///|
enum ToggleEvent {
  Flip
} derive(Eq, Debug)

///|
struct ToggleContext {
  mut flips : Int
} derive(Eq, Debug)

///|
/// Exercise the core transition lookup and action path with a fixed workload.
pub fn run_machine(iterations : Int) -> BenchmarkResult {
  let context = { flips: 0 }
  let machine = @core.Machine::new(ToggleState::Off, context)
  machine.add_transition(ToggleState::Off, ToggleEvent::Flip, ToggleState::On, action=fn(
    c,
    _e,
  ) {
    c.flips = c.flips + 1
  })
  machine.add_transition(ToggleState::On, ToggleEvent::Flip, ToggleState::Off, action=fn(
    c,
    _e,
  ) {
    c.flips = c.flips + 1
  })
  let mut successes = 0
  for _i = 0; _i < iterations; _i = _i + 1 {
    if machine.send(ToggleEvent::Flip) {
      successes = successes + 1
    }
  }
  BenchmarkResult::new(
    "core.toggle",
    iterations,
    successes,
    iterations - successes,
    "two-state transition and mutable action",
  )
}

///|
struct WorkflowContext {
  mut completed : Int
  mut calls : Int
} derive(Eq, Debug)

///|
/// Exercise a successful workflow path and verify that each action is called once.
pub fn run_workflow(iterations : Int) -> BenchmarkResult {
  let context = { completed: 0, calls: 0 }
  let workflow = @workflow.Workflow::new("benchmark", context)
  workflow.add_step("prepare", fn(c) {
    c.calls = c.calls + 1
    true
  })
  workflow.add_step("execute", fn(c) {
    c.calls = c.calls + 1
    c.completed = c.completed + 1
    true
  })
  let mut successes = 0
  for _i = 0; _i < iterations; _i = _i + 1 {
    let result = workflow.run_all()
    if result is @workflow.StepStatus::Success {
      successes = successes + 1
    }
    workflow.reset()
  }
  BenchmarkResult::new(
    "workflow.two-step",
    iterations * 2,
    successes,
    iterations - successes,
    "two-step success path with explicit reset",
  )
}

///|
/// Exercise one-shot and periodic scheduler behavior without wall-clock noise.
pub fn run_scheduler(iterations : Int) -> BenchmarkResult {
  let scheduler = @timer.Scheduler::new()
  let mut triggered = 0
  for i = 0; i < iterations; i = i + 1 {
    ignore(scheduler.schedule_after(1L, i))
    let events = scheduler.tick(1L)
    triggered = triggered + events.length()
  }
  BenchmarkResult::new(
    "timer.one-shot",
    iterations,
    triggered,
    iterations - triggered,
    "logical ticks with one event per tick",
  )
}

///|
/// A small standard suite used by CI and release notes.
pub fn run_suite(iterations : Int) -> Array[BenchmarkResult] {
  [run_machine(iterations), run_workflow(iterations), run_scheduler(iterations)]
}
