///|
enum TrafficLightEvent {
  TimerGreenToYellow
  TimerYellowToRed
  TimerRedToGreen
  EmergencyOverride
} derive(Eq, Debug)

///|
test "scheduler one-shot and periodic events" {
  let sched = @timer.Scheduler::new()

  let id1 = sched.schedule_after(1000L, TrafficLightEvent::TimerGreenToYellow)
  let _id2 = sched.schedule_after(1500L, TrafficLightEvent::TimerYellowToRed)
  let _id3 = sched.schedule_after(4500L, TrafficLightEvent::TimerRedToGreen)
  let _id4 = sched.schedule_periodic(
    2000L,
    TrafficLightEvent::EmergencyOverride,
  )

  let evs1 = sched.tick(1200L)
  debug_inspect(evs1, content="[TimerGreenToYellow]")
  debug_inspect(sched.get_time(), content="1200")

  let evs2 = sched.advance_to(2500L)
  debug_inspect(evs2, content="[TimerYellowToRed, EmergencyOverride]")

  let cancelled = sched.cancel(id1)
  debug_inspect(cancelled, content="false")

  let evs3 = sched.advance_to(5000L)
  debug_inspect(evs3, content="[EmergencyOverride, TimerRedToGreen]")
}

///|
test "scheduler boundary conditions" {
  let sched = @timer.Scheduler::new()

  // Negative or zero timeout should fire immediately on next tick
  let _id1 = sched.schedule_after(0L, TrafficLightEvent::TimerGreenToYellow)
  let _id2 = sched.schedule_after(-100L, TrafficLightEvent::TimerYellowToRed)

  let evs1 = sched.tick(1L)
  debug_inspect(evs1, content="[TimerYellowToRed, TimerGreenToYellow]")

  // Exact interval firing
  let _id3 = sched.schedule_after(1000L, TrafficLightEvent::TimerRedToGreen)
  let evs2 = sched.tick(999L) // Target is 1L + 1000L = 1001L. tick(999L) gets us to 1000L.
  debug_inspect(evs2, content="[]")

  let evs3 = sched.tick(1L)
  debug_inspect(evs3, content="[TimerRedToGreen]")

  // Cancel a non-existent timer
  let cancelled = sched.cancel(999)
  debug_inspect(cancelled, content="false")

  // Timer overflow/very large timeout: causes trigger_at to overflow and become negative, 
  // triggering immediately.
  let _id4 = sched.schedule_after(
    9223372036854775000L,
    TrafficLightEvent::EmergencyOverride,
  )
  let evs4 = sched.tick(2000L)
  debug_inspect(evs4, content="[EmergencyOverride]")
}
