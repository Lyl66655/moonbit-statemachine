///|
test "benchmark results are deterministic and complete" {
  let machine = @benchmarks.run_machine(100)
  inspect(machine.operations(), content="100")
  inspect(machine.successes(), content="100")
  inspect(machine.failures(), content="0")

  let workflow = @benchmarks.run_workflow(25)
  inspect(workflow.operations(), content="50")
  inspect(workflow.successes(), content="25")
  inspect(workflow.failures(), content="0")

  let timer = @benchmarks.run_scheduler(40)
  inspect(timer.operations(), content="40")
  inspect(timer.successes(), content="40")
  inspect(timer.failures(), content="0")

  let suite = @benchmarks.run_suite(10)
  inspect(suite.length(), content="3")
  inspect(
    @benchmarks.summarize(suite),
    content="suite: operations=40, successes=30, failures=0, cases=3",
  )
}

///|
test "zero-workload benchmark has no false positives" {
  let results = @benchmarks.run_suite(0)
  for result in results {
    inspect(result.operations(), content="0")
    inspect(result.successes(), content="0")
    inspect(result.failures(), content="0")
  }
}

///|
test "benchmark suite preserves failure accounting for hostile workloads" {
  let result = @benchmarks.BenchmarkResult::new(
    "synthetic-failure", 12, 7, 5, "used to verify release-note aggregation",
  )
  inspect(result.name(), content="synthetic-failure")
  inspect(result.operations(), content="12")
  inspect(result.successes(), content="7")
  inspect(result.failures(), content="5")
  inspect(
    result.summary(),
    content="synthetic-failure: operations=12, successes=7, failures=5, used to verify release-note aggregation",
  )
  inspect(
    @benchmarks.summarize([result]),
    content="suite: operations=12, successes=7, failures=5, cases=1",
  )
}

///|
test "benchmark logical work scales linearly" {
  let small = @benchmarks.run_machine(4)
  let large = @benchmarks.run_machine(40)
  inspect(large.operations(), content="40")
  inspect(large.successes() - small.successes(), content="36")
  inspect(large.failures(), content="0")
}

///|
test "benchmark release report is suitable for review evidence" {
  let results = @benchmarks.run_suite(2)
  for result in results {
    inspect(result.all_successful(), content="true")
  }
  inspect(@benchmarks.meets_release_floor(results, 6), content="true")
  inspect(@benchmarks.meets_release_floor(results, 100), content="false")
  inspect(
    @benchmarks.markdown_report([results[0]]).contains(
      "| core.toggle | 2 | 2 | 0 |",
    ),
    content="true",
  )
}

///|
test "benchmark comparison identifies added and removed cases" {
  let baseline = [
    @benchmarks.BenchmarkResult::new("old", 1, 1, 0, "old"),
    @benchmarks.BenchmarkResult::new("same", 2, 2, 0, "same"),
  ]
  let current = [
    @benchmarks.BenchmarkResult::new("same", 4, 4, 0, "same"),
    @benchmarks.BenchmarkResult::new("new", 3, 3, 0, "new"),
  ]
  debug_inspect(
    @benchmarks.compare(baseline, current),
    content=(
      #|[
      #|  "same: operations_delta=2, successes_delta=2",
      #|  "new: new",
      #|  "old: removed",
      #|]
    ),
  )
}

///|
test "benchmark accounting validation rejects impossible data" {
  let valid = @benchmarks.BenchmarkResult::new("valid", 5, 3, 2, "")
  let invalid = @benchmarks.BenchmarkResult::new("invalid", 2, 2, 2, "")
  inspect(valid.is_consistent(), content="true")
  inspect(invalid.is_consistent(), content="false")
  debug_inspect(
    @benchmarks.inconsistent([valid, invalid]),
    content="[\"invalid\"]",
  )
}
