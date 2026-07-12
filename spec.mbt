///|
/// Spec-driven development contract for MoonBit Statemachine
/// This file defines the formal contract and core types for the hierarchical state machine engine.

///|
declare pub type State[S]

///|
declare pub type Event[E]

///|
declare pub type Machine[S, E, C]

///|
declare pub fn[S, E, C] Machine::new(initial : S, context : C) -> Machine[S, E, C]

///|
declare pub fn[S, E, C] Machine::send(self : Machine[S, E, C], event : E) -> Bool raise
