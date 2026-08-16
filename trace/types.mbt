///|
/// A logical operation captured by an execution trace.
pub(all) enum Operation {
  Enter
  Exit
  Transition
  Retry
  Timer
  Checkpoint
  Failure
} derive(Eq, Debug)

///|
/// A serializable trace record. The library deliberately stores strings so it
/// can trace any user's state/event type without imposing a serialization trait.
pub(all) struct Record {
  sequence : Int
  timestamp : Int64
  operation : Operation
  subject : String
  detail : String
} derive(Eq, Debug)

///|
/// An append-only trace with optional capacity control.
pub(all) struct Trace {
  mut next_sequence : Int
  mut records : Array[Record]
  capacity : Int
}

///|
/// A cursor used to inspect or replay a trace from a stable position.
pub(all) struct Cursor {
  source : Trace
  mut position : Int
}

///|
pub fn Record::new(
  sequence : Int,
  timestamp : Int64,
  operation : Operation,
  subject : String,
  detail : String,
) -> Record {
  { sequence, timestamp, operation, subject, detail }
}

///|
pub fn Record::sequence(self : Record) -> Int {
  self.sequence
}

///|
pub fn Record::timestamp(self : Record) -> Int64 {
  self.timestamp
}

///|
pub fn Record::operation(self : Record) -> Operation {
  self.operation
}

///|
pub fn Record::subject(self : Record) -> String {
  self.subject
}

///|
pub fn Record::detail(self : Record) -> String {
  self.detail
}

///|
pub fn Trace::new(capacity? : Int = 0) -> Trace {
  { next_sequence: 0, records: [], capacity }
}

///|
pub fn Trace::length(self : Trace) -> Int {
  self.records.length()
}

///|
pub fn Trace::is_empty(self : Trace) -> Bool {
  self.records.length() == 0
}

///|
pub fn Trace::records(self : Trace) -> Array[Record] {
  self.records
}

///|
pub fn Trace::last(self : Trace) -> Record? {
  if self.records.length() == 0 {
    None
  } else {
    Some(self.records[self.records.length() - 1])
  }
}

///|
pub fn Trace::clear(self : Trace) -> Unit {
  self.records = []
}

///|
pub fn Trace::cursor(self : Trace) -> Cursor {
  { source: self, position: 0 }
}

///|
pub fn Cursor::position(self : Cursor) -> Int {
  self.position
}

///|
pub fn Cursor::remaining(self : Cursor) -> Int {
  self.source.records.length() - self.position
}

///|
pub fn Cursor::next(self : Cursor) -> Record? {
  if self.position >= self.source.records.length() {
    None
  } else {
    let result = self.source.records[self.position]
    self.position = self.position + 1
    Some(result)
  }
}

///|
pub fn Cursor::reset(self : Cursor) -> Unit {
  self.position = 0
}
