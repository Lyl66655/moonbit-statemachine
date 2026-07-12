///|
/// Create a new deterministic event scheduler starting at `initial_time` (default 0).
pub fn[E] Scheduler::new(initial_time~ : Int64 = 0L) -> Scheduler[E] {
  { next_id: 1, current_time: initial_time, events: [] }
}

///|
/// Get the current simulation timestamp of the scheduler.
pub fn[E] Scheduler::get_time(self : Scheduler[E]) -> Int64 {
  self.current_time
}

///|
/// Schedule a one-shot event to trigger after `delay` milliseconds/ticks.
/// Returns a unique timer ID that can be used for cancellation.
pub fn[E] Scheduler::schedule_after(
  self : Scheduler[E],
  delay : Int64,
  event : E
) -> Int {
  let id = self.next_id
  self.next_id = self.next_id + 1
  let trigger_at = self.current_time + delay
  self.events.push({ id, event, trigger_at, interval: 0L })
  id
}

///|
/// Schedule a repeating periodic event to trigger every `interval` milliseconds/ticks.
/// Returns a unique timer ID.
pub fn[E] Scheduler::schedule_periodic(
  self : Scheduler[E],
  interval : Int64,
  event : E
) -> Int {
  let id = self.next_id
  self.next_id = self.next_id + 1
  let trigger_at = self.current_time + interval
  self.events.push({ id, event, trigger_at, interval })
  id
}

///|
/// Cancel a previously scheduled timer by its ID.
/// Returns `true` if the timer was found and cancelled, `false` otherwise.
pub fn[E] Scheduler::cancel(self : Scheduler[E], timer_id : Int) -> Bool {
  for i = 0; i < self.events.length(); i = i + 1 {
    if self.events[i].id == timer_id {
      let _ = self.events.remove(i)
      return true
    }
  }
  false
}

///|
/// Advance simulation time by `delta` milliseconds/ticks and return all triggered events in chronological order.
pub fn[E] Scheduler::tick(self : Scheduler[E], delta : Int64) -> Array[E] {
  self.advance_to(self.current_time + delta)
}

///|
/// Advance simulation time to `target_time` and return all triggered events in chronological order.
pub fn[E] Scheduler::advance_to(
  self : Scheduler[E],
  target_time : Int64
) -> Array[E] {
  if target_time <= self.current_time {
    return []
  }
  let triggered = []
  while true {
    let mut earliest_idx = -1
    let mut earliest_time = target_time + 1L
    for i = 0; i < self.events.length(); i = i + 1 {
      if self.events[i].trigger_at <= target_time {
        if earliest_idx == -1 || self.events[i].trigger_at < earliest_time {
          earliest_idx = i
          earliest_time = self.events[i].trigger_at
        }
      }
    }
    if earliest_idx == -1 {
      break
    }
    let ev = self.events[earliest_idx]
    self.current_time = ev.trigger_at
    triggered.push(ev.event)
    
    if ev.interval > 0L {
      self.events[earliest_idx] = {
        id: ev.id,
        event: ev.event,
        trigger_at: ev.trigger_at + ev.interval,
        interval: ev.interval,
      }
    } else {
      let _ = self.events.remove(earliest_idx)
    }
  }
  self.current_time = target_time
  triggered
}
