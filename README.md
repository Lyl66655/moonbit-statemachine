# MoonBit StateMachine & Workflow Engine

An open-source MoonBit library for building hierarchical state machines, deterministic workflow pipelines, and event schedulers.

The project is organized around six practical building blocks:

- `core/` for the base state transition engine
- `hsm/` for hierarchical state machines with event bubbling and LCA-based lifecycle handling
- `workflow/` for sequential pipelines with retry and failure handling
- `timer/` for deterministic timeout and interval simulation
- `export/` for Mermaid and PlantUML diagram export
- `examples/` for executable demos and reference usage

## What it does

- Models complex stateful logic with explicit guards, actions, and lifecycle hooks
- Supports parent-child state hierarchies and bubbling event dispatch
- Adds a simple workflow runner for agent pipelines, task orchestration, and recoverable step execution
- Provides deterministic timer behavior for testable timeout logic
- Exports diagrams that can be embedded directly in docs and READMEs

## Repository Layout

| Package | Path | Purpose |
| --- | --- | --- |
| Core | `core/` | Transition engine, guards, and lifecycle hooks |
| HSM | `hsm/` | Hierarchical states, event bubbling, and LCA resolution |
| Workflow | `workflow/` | Sequential pipelines with retry policies |
| Timer | `timer/` | Deterministic scheduler and timeout simulation |
| Export | `export/` | Mermaid and PlantUML generator |
| Examples | `examples/` | Agent workflow and game state demos |

## Quick Start

```mbt
enum State { Locked; Unlocked } derive(Eq, Debug)
enum Event { Coin; Push } derive(Eq, Debug)
struct Context { mut coins : Int } derive(Eq, Debug)

let ctx = { coins: 0 }
let fsm = @core.Machine::new(State::Locked, ctx)

fsm.add_transition(
  State::Locked,
  Event::Coin,
  State::Unlocked,
  cond=fn(c, _e) { c.coins < 5 },
  action=fn(c, _e) { c.coins = c.coins + 1 },
)

fsm.add_transition(State::Unlocked, Event::Push, State::Locked)
let transitioned = fsm.send(Event::Coin)
```

For more examples, see:

- [Executable docs](./README.mbt.md)
- [AI agent workflow demo](./examples/ai_agent_workflow/demo.mbt)
- [Game FSM demo](./examples/game_fsm/demo.mbt)

## Quality Checks

The repository is expected to stay clean under the MoonBit toolchain checks used by the competition:

- `moon check`
- `moon fmt --deny-warn`
- `moon info --deny-warn`
- `moon test`

On the current local toolchain, `moon check` and `moon test` pass. The repository CI is pinned to MoonBit `0.10.3` so the stricter format and info checks run with the toolchain version requested by the competition.

## Competition Notes

This repository is prepared for the OSC 2026 MoonBit track:

- Open-source license: Apache-2.0
- Default branch: `master`
- Remote mirrors: GitHub and GitLink
- Development history: preserved in git commits

## Current Status

- MoonBit source files: 20
- MoonBit source lines: 1,222
- Test count: 10
- Test result: 10 passed, 0 failed

The current implementation is solid as a reusable library foundation. The competition guide recommends substantially larger effective MoonBit code volume for final review, so continued feature expansion will still strengthen the submission.

## License

Apache-2.0. See [LICENSE](./LICENSE).
