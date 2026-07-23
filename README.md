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

### Installation

To add this package to your project, run:

```bash
moon add ylyl/moonbit-workflow-engine
```

### Basic Usage

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

### Running Examples

You can execute the provided demos directly from the command line:

```bash
moon run examples/ai_agent_workflow
```
**Expected Output:**
```
[Agent] Task initialized.
[Agent] Planning steps...
[Agent] Step 1 executed.
[Agent] Workflow completed successfully.
```
*(Output may vary slightly based on the specific demo logic)*

```bash
moon run examples/game_fsm
```
**Expected Output:**
```
[Game] Spawned boss at 100% health
[Game] Player attacking... boss health at 80%
[Game] Boss phase changed to Enraged
```

For more details, see:

- [Executable docs](./README.mbt.md)
- [AI agent workflow demo](./examples/ai_agent_workflow/demo.mbt)
- [Game FSM demo](./examples/game_fsm/demo.mbt)

## Quality Checks

To verify the repository locally, you can run the following standard MoonBit checks:

```bash
moon check
moon build
moon test
```

For stricter formatting and info warnings (as required by the competition):

```bash
moon fmt --deny-warn
moon info --deny-warn
```

On the current local toolchain, `moon check`, `moon build`, and `moon test` pass. The repository CI is pinned to MoonBit `0.10.3` so the stricter format and info checks run with the toolchain version requested by the competition.

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
