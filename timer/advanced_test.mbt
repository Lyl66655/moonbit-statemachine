///|
enum TimerEvent {
  A
  B
} derive(Eq, Debug)

///|
test "scheduler introspection exposes pending work" {
  let scheduler = @timer.Scheduler::new(initial_time=100L)
  let first = scheduler.schedule_after(50L, TimerEvent::A)
  let second = scheduler.schedule_after(20L, TimerEvent::B)
  inspect(scheduler.pending_count(), content="2")
  inspect(scheduler.contains(first), content="true")
  debug_inspect(scheduler.next_due(), content="Some(120)")
  inspect(scheduler.cancel(second), content="true")
  debug_inspect(scheduler.next_due(), content="Some(150)")
  inspect(scheduler.cancel_all(), content="1")
  inspect(scheduler.pending_count(), content="0")
  debug_inspect(scheduler.next_due(), content="None")
}

///|
test "scheduler clear works after a periodic timer" {
  let scheduler = @timer.Scheduler::new()
  ignore(scheduler.schedule_periodic(10L, TimerEvent::A))
  ignore(scheduler.schedule_after(5L, TimerEvent::B))
  inspect(scheduler.cancel_all(), content="2")
  debug_inspect(scheduler.tick(100L), content="[]")
  inspect(scheduler.get_time(), content="100")
}

///|
test "scheduler rejects invalid periodic intervals without registering them" {
  let scheduler = @timer.Scheduler::new()
  debug_inspect(
    scheduler.schedule_periodic_checked(0L, TimerEvent::A),
    content="None",
  )
  debug_inspect(
    scheduler.schedule_periodic_checked(-10L, TimerEvent::B),
    content="None",
  )
  inspect(scheduler.pending_count(), content="0")

  // The legacy Int-returning API remains safe for callers that cannot use the
  // checked variant: malformed input becomes one one-shot event.
  ignore(scheduler.schedule_periodic(0L, TimerEvent::A))
  debug_inspect(scheduler.tick(1L), content="[A]")
  inspect(scheduler.pending_count(), content="0")
}
