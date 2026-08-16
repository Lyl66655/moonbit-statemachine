///|
pub fn init_demo() -> Unit {
  let hsm : @hsm.HSM[Int, Int, Unit] = @hsm.HSM::new(0, ())
  hsm.add_state(1, parent=0)
  hsm.add_state(2, parent=1)
  hsm.add_transition(0, 1, 1)
  hsm.add_transition(1, 2, 2)
  println("[Game] Spawned boss at 100% health")
  ignore(hsm.send(1))
  println("[Game] Player attacking... boss health at 80%")
  ignore(hsm.send(2))
  println("[Game] Boss phase changed to Enraged")
  let diagram = @export.export_hsm_mermaid(hsm, fn(x : Int) { x.to_string() }, fn(
    y : Int,
  ) {
    y.to_string()
  })
  let _ = diagram.length()
}
