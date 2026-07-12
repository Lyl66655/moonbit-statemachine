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
  let _id4 = sched.schedule_periodic(2000L, TrafficLightEvent::EmergencyOverride)

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
