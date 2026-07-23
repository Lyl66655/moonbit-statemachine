///|
pub fn init_demo() -> Unit {
  let hsm : @hsm.HSM[Int, Int, Unit] = @hsm.HSM::new(0, ())
  let _ = @export.export_hsm_mermaid(hsm, fn(x : Int) { x.to_string() }, fn(
    y : Int,
  ) {
    y.to_string()
  })
}
