///|
/// Represents a scheduled or periodic event timer in the state machine scheduler.
pub(all) struct ScheduledEvent[E] {
  id : Int
  event : E
  trigger_at : Int64
  interval : Int64
}

///|
/// A deterministic event timer and scheduler for driving delayed state transitions and timeouts.
pub(all) struct Scheduler[E] {
  mut next_id : Int
  mut current_time : Int64
  events : Array[ScheduledEvent[E]]
}
