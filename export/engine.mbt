///|
/// Export a Hierarchical State Machine as a Mermaid.js `stateDiagram-v2` specification.
pub fn[S : Eq, E, C] export_hsm_mermaid(
  hsm : @hsm.HSM[S, E, C],
  state_name : (S) -> String,
  event_name : (E) -> String,
) -> String {
  let mut out = "stateDiagram-v2\n"
  out = out + "  [*] --> " + state_name(hsm.get_state()) + "\n"

  for i = 0; i < hsm.hierarchy.length(); i = i + 1 {
    let hs = hsm.hierarchy[i]
    let s_name = state_name(hs.state)
    let mut has_children = false
    for j = 0; j < hsm.hierarchy.length(); j = j + 1 {
      match hsm.hierarchy[j].parent {
        Some(p) =>
          if p == hs.state {
            has_children = true
            break
          }
        None => ()
      }
    }
    if has_children {
      out = out + "  state " + s_name + " {\n"
      match hs.initial_child {
        Some(init_ch) => out = out + "    [*] --> " + state_name(init_ch) + "\n"
        None => ()
      }
      out = out + "  }\n"
    }
  }

  for i = 0; i < hsm.transitions.length(); i = i + 1 {
    let t = hsm.transitions[i]
    out = out +
      "  " +
      state_name(t.from_state) +
      " --> " +
      state_name(t.to_state) +
      " : " +
      event_name(t.event) +
      "\n"
  }
  out
}

///|
/// Export a Hierarchical State Machine as a PlantUML `@startuml` specification.
pub fn[S : Eq, E, C] export_hsm_plantuml(
  hsm : @hsm.HSM[S, E, C],
  state_name : (S) -> String,
  event_name : (E) -> String,
) -> String {
  let mut out = "@startuml\n"
  out = out + "[*] --> " + state_name(hsm.get_state()) + "\n"

  for i = 0; i < hsm.hierarchy.length(); i = i + 1 {
    let hs = hsm.hierarchy[i]
    let s_name = state_name(hs.state)
    let mut has_children = false
    for j = 0; j < hsm.hierarchy.length(); j = j + 1 {
      match hsm.hierarchy[j].parent {
        Some(p) =>
          if p == hs.state {
            has_children = true
            break
          }
        None => ()
      }
    }
    if has_children {
      out = out + "state " + s_name + " {\n"
      match hs.initial_child {
        Some(init_ch) => out = out + "  [*] --> " + state_name(init_ch) + "\n"
        None => ()
      }
      out = out + "}\n"
    }
  }

  for i = 0; i < hsm.transitions.length(); i = i + 1 {
    let t = hsm.transitions[i]
    out = out +
      state_name(t.from_state) +
      " --> " +
      state_name(t.to_state) +
      " : " +
      event_name(t.event) +
      "\n"
  }
  out = out + "@enduml\n"
  out
}

///|
/// Export a sequential Workflow pipeline as a Mermaid.js `flowchart TD` specification.
pub fn[C] export_workflow_mermaid(wf : @workflow.Workflow[C]) -> String {
  let mut out = "flowchart TD\n"
  out = out + "  Start([Start: " + wf.name + "]) --> Step0\n"

  for i = 0; i < wf.steps.length(); i = i + 1 {
    let st = wf.steps[i]
    let step_id = "Step" + i.to_string()
    let next_id = if i + 1 < wf.steps.length() {
      "Step" + (i + 1).to_string()
    } else {
      "Success([Success])"
    }
    out = out +
      "  " +
      step_id +
      "[" +
      st.name +
      "] -->|Success| " +
      next_id +
      "\n"
    if st.max_retries > 0 {
      out = out +
        "  " +
        step_id +
        " -.->|Retry (" +
        st.max_retries.to_string() +
        " max)| " +
        step_id +
        "\n"
    }
    out = out + "  " + step_id + " -->|Fail| Failed([Failed])\n"
  }
  out
}
