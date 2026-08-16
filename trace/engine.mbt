///|
/// Append a record and enforce a positive capacity as a ring buffer.
pub fn Trace::append(
  self : Trace,
  timestamp : Int64,
  operation : Operation,
  subject : String,
  detail : String,
) -> Record {
  let record = Record::new(
    self.next_sequence,
    timestamp,
    operation,
    subject,
    detail,
  )
  self.next_sequence = self.next_sequence + 1
  self.records.push(record)
  if self.capacity > 0 && self.records.length() > self.capacity {
    let _ = self.records.remove(0)
  }
  record
}

///|
/// Append a named checkpoint that can be used as a replay boundary.
pub fn Trace::checkpoint(
  self : Trace,
  timestamp : Int64,
  name : String,
) -> Record {
  self.append(timestamp, Operation::Checkpoint, name, "checkpoint")
}

///|
/// Find records matching an operation, preserving trace order.
pub fn Trace::filter_operation(
  self : Trace,
  operation : Operation,
) -> Array[Record] {
  let result = []
  for record in self.records {
    if record.operation == operation {
      result.push(record)
    }
  }
  result
}

///|
/// Find records for a subject, useful for one state or workflow step.
pub fn Trace::filter_subject(self : Trace, subject : String) -> Array[Record] {
  let result = []
  for record in self.records {
    if record.subject == subject {
      result.push(record)
    }
  }
  result
}

///|
/// Count records for a subject without allocating a filtered array.
pub fn Trace::count_subject(self : Trace, subject : String) -> Int {
  let mut count = 0
  for record in self.records {
    if record.subject == subject {
      count = count + 1
    }
  }
  count
}

///|
/// Count records of an operation without allocating a filtered array.
pub fn Trace::count_operation(self : Trace, operation : Operation) -> Int {
  let mut count = 0
  for record in self.records {
    if record.operation == operation {
      count = count + 1
    }
  }
  count
}

///|
/// Return the first checkpoint after a timestamp.
pub fn Trace::checkpoint_after(self : Trace, timestamp : Int64) -> Record? {
  for record in self.records {
    if record.operation == Operation::Checkpoint &&
      record.timestamp >= timestamp {
      return Some(record)
    }
  }
  None
}

///|
/// Return the number of records at or after a timestamp.
pub fn Trace::count_at_or_after(self : Trace, timestamp : Int64) -> Int {
  let mut count = 0
  for record in self.records {
    if record.timestamp >= timestamp {
      count = count + 1
    }
  }
  count
}

///|
/// Count failure records for health summaries.
pub fn Trace::failure_count(self : Trace) -> Int {
  self.count_operation(Operation::Failure)
}

///|
/// Return the most recent failure record, if any.
pub fn Trace::last_failure(self : Trace) -> Record? {
  for i = self.records.length() - 1; i >= 0; i = i - 1 {
    if self.records[i].operation == Operation::Failure {
      return Some(self.records[i])
    }
  }
  None
}

///|
/// Return the first record at or after a logical timestamp.
pub fn Trace::at_or_after(self : Trace, timestamp : Int64) -> Record? {
  for record in self.records {
    if record.timestamp >= timestamp {
      return Some(record)
    }
  }
  None
}

///|
/// Return all records in the half-open sequence window [start, end).
pub fn Trace::window(self : Trace, start : Int, end : Int) -> Array[Record] {
  let result = []
  for record in self.records {
    if record.sequence >= start && record.sequence < end {
      result.push(record)
    }
  }
  result
}

///|
/// Return a compact deterministic summary for logs and golden tests.
pub fn Trace::summary(self : Trace) -> String {
  let mut out = "records=" + self.records.length().to_string()
  for record in self.records {
    out = out +
      "\n" +
      record.sequence.to_string() +
      "@" +
      record.timestamp.to_string() +
      " " +
      operation_name(record.operation) +
      " " +
      record.subject
  }
  out
}

///|
fn operation_name(operation : Operation) -> String {
  match operation {
    Operation::Enter => "enter"
    Operation::Exit => "exit"
    Operation::Transition => "transition"
    Operation::Retry => "retry"
    Operation::Timer => "timer"
    Operation::Checkpoint => "checkpoint"
    Operation::Failure => "failure"
  }
}

///|
/// Compare two traces by logical records, ignoring storage capacity details.
pub fn equivalent(left : Trace, right : Trace) -> Bool {
  if left.records.length() != right.records.length() {
    return false
  }
  for i = 0; i < left.records.length(); i = i + 1 {
    if left.records[i] != right.records[i] {
      return false
    }
  }
  true
}
