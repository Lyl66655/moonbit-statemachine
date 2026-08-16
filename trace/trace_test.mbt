///|
test "trace captures and filters deterministic records" {
  let trace = @trace.Trace::new()
  ignore(trace.append(0L, @trace.Operation::Enter, "Locked", "initial"))
  ignore(
    trace.append(2L, @trace.Operation::Transition, "Coin", "Locked -> Unlocked"),
  )
  ignore(trace.append(3L, @trace.Operation::Exit, "Locked", "leave"))
  ignore(trace.checkpoint(4L, "after-coin"))

  inspect(trace.length(), content="4")
  inspect(trace.filter_subject("Locked").length(), content="2")
  inspect(
    trace.filter_operation(@trace.Operation::Transition).length(),
    content="1",
  )
  inspect(trace.at_or_after(3L) is Some(_), content="true")
  inspect(trace.window(1, 3).length(), content="2")
  inspect(
    trace.summary(),
    content=(
      #|records=4
      #|0@0 enter Locked
      #|1@2 transition Coin
      #|2@3 exit Locked
      #|3@4 checkpoint after-coin
    ),
  )
}

///|
test "trace capacity is a ring buffer and cursor is replayable" {
  let trace = @trace.Trace::new(capacity=2)
  ignore(trace.append(1L, @trace.Operation::Timer, "a", "first"))
  ignore(trace.append(2L, @trace.Operation::Timer, "b", "second"))
  ignore(trace.append(3L, @trace.Operation::Timer, "c", "third"))
  inspect(trace.length(), content="2")
  inspect(trace.records()[0].subject(), content="b")
  inspect(trace.records()[1].subject(), content="c")

  let cursor = trace.cursor()
  inspect(cursor.remaining(), content="2")
  ignore(cursor.next())
  inspect(cursor.position(), content="1")
  ignore(cursor.next())
  inspect(cursor.next() is None, content="true")
  cursor.reset()
  inspect(cursor.remaining(), content="2")
}

///|
test "equivalent traces make stable regression fixtures" {
  let left = @trace.Trace::new()
  let right = @trace.Trace::new()
  ignore(left.append(5L, @trace.Operation::Failure, "deploy", "network"))
  ignore(right.append(5L, @trace.Operation::Failure, "deploy", "network"))
  inspect(@trace.equivalent(left, right), content="true")
  ignore(right.append(6L, @trace.Operation::Retry, "deploy", "retry-1"))
  inspect(@trace.equivalent(left, right), content="false")
}

///|
test "trace accessors expose immutable record values" {
  let trace = @trace.Trace::new()
  let record = trace.append(42L, @trace.Operation::Retry, "compile", "retry-2")
  inspect(record.sequence(), content="0")
  inspect(record.timestamp(), content="42")
  debug_inspect(record.operation(), content="Retry")
  inspect(record.subject(), content="compile")
  inspect(record.detail(), content="retry-2")
  debug_inspect(
    trace.last(),
    content=(
      #|Some(
      #|  {
      #|    sequence: 0,
      #|    timestamp: 42,
      #|    operation: Retry,
      #|    subject: "compile",
      #|    detail: "retry-2",
      #|  },
      #|)
    ),
  )
  trace.clear()
  inspect(trace.is_empty(), content="true")
}

///|
test "trace window handles empty and out of range intervals" {
  let trace = @trace.Trace::new()
  ignore(trace.append(1L, @trace.Operation::Enter, "a", ""))
  ignore(trace.append(2L, @trace.Operation::Exit, "a", ""))
  inspect(trace.window(2, 2).length(), content="0")
  inspect(trace.window(99, 100).length(), content="0")
  debug_inspect(trace.at_or_after(99L), content="None")
}

///|
test "trace aggregate queries avoid unnecessary allocations" {
  let trace = @trace.Trace::new()
  ignore(trace.append(1L, @trace.Operation::Enter, "job", "start"))
  ignore(trace.append(2L, @trace.Operation::Retry, "job", "retry"))
  ignore(trace.append(3L, @trace.Operation::Checkpoint, "job", "safe"))
  ignore(trace.append(4L, @trace.Operation::Failure, "other", "stop"))
  inspect(trace.count_subject("job"), content="3")
  inspect(trace.count_operation(@trace.Operation::Retry), content="1")
  inspect(trace.count_at_or_after(3L), content="2")
  debug_inspect(
    trace.checkpoint_after(2L),
    content=(
      #|Some(
      #|  {
      #|    sequence: 2,
      #|    timestamp: 3,
      #|    operation: Checkpoint,
      #|    subject: "job",
      #|    detail: "safe",
      #|  },
      #|)
    ),
  )
  debug_inspect(trace.checkpoint_after(4L), content="None")
}

///|
test "trace failure summary points to the latest failure" {
  let trace = @trace.Trace::new()
  ignore(trace.append(1L, @trace.Operation::Failure, "build", "compile"))
  ignore(trace.append(2L, @trace.Operation::Retry, "build", "retry"))
  ignore(trace.append(3L, @trace.Operation::Failure, "deploy", "network"))
  inspect(trace.failure_count(), content="2")
  debug_inspect(
    trace.last_failure(),
    content=(
      #|Some(
      #|  {
      #|    sequence: 2,
      #|    timestamp: 3,
      #|    operation: Failure,
      #|    subject: "deploy",
      #|    detail: "network",
      #|  },
      #|)
    ),
  )
}
