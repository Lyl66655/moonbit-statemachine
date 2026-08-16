///|
enum ControlTimerEvent {
  A
  B
} derive(Eq, Debug)

///|
test "scheduler supports absolute timestamps and stable IDs" {
  let scheduler = @timer.Scheduler::new(initial_time=100L)
  let first = scheduler.schedule_at(120L, ControlTimerEvent::A)
  let second = scheduler.schedule_at(150L, ControlTimerEvent::B)
  debug_inspect(scheduler.timer_ids(), content="[1, 2]")
  debug_inspect(scheduler.next_due(), content="Some(120)")
  debug_inspect(scheduler.tick(30L), content="[A]")
  inspect(scheduler.contains(first), content="false")
  inspect(scheduler.contains(second), content="true")
  debug_inspect(scheduler.tick(1L), content="[]")
  debug_inspect(scheduler.tick(29L), content="[B]")
  inspect(scheduler.pending_count(), content="0")
}
