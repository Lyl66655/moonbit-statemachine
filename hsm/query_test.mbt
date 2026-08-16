///|
enum QueryState {
  Root
  Left
  LeftLeaf
  Right
  RightLeaf
} derive(Eq, Debug)

///|
enum QueryEvent {
  Noop
} derive(Eq, Debug)

///|
test "hsm ancestry and lowest common ancestor queries" {
  let hsm : @hsm.HSM[QueryState, QueryEvent, Unit] = @hsm.HSM::new(
    QueryState::LeftLeaf,
    (),
  )
  ignore(QueryEvent::Noop)
  hsm.add_state(QueryState::Left, parent=QueryState::Root)
  hsm.add_state(QueryState::LeftLeaf, parent=QueryState::Left)
  hsm.add_state(QueryState::Right, parent=QueryState::Root)
  hsm.add_state(QueryState::RightLeaf, parent=QueryState::Right)
  hsm.add_state(QueryState::Root)

  inspect(
    hsm.is_descendant(QueryState::LeftLeaf, QueryState::Root),
    content="true",
  )
  inspect(
    hsm.is_descendant(QueryState::Right, QueryState::Left),
    content="false",
  )
  debug_inspect(
    hsm.lowest_common_ancestor(QueryState::LeftLeaf, QueryState::RightLeaf),
    content="Some(Root)",
  )
  debug_inspect(
    hsm.transition_path(QueryState::LeftLeaf, QueryState::RightLeaf),
    content="[LeftLeaf, Left, Right, RightLeaf]",
  )
}

///|
test "hsm query for unknown states is safe" {
  let hsm : @hsm.HSM[QueryState, QueryEvent, Unit] = @hsm.HSM::new(
    QueryState::Root,
    (),
  )
  inspect(
    hsm.is_descendant(QueryState::Left, QueryState::Root),
    content="false",
  )
  debug_inspect(
    hsm.lowest_common_ancestor(QueryState::Left, QueryState::Right),
    content="None",
  )
  debug_inspect(
    hsm.transition_path(QueryState::Left, QueryState::Right),
    content="[]",
  )
}

///|
test "hsm cyclic metadata is bounded during runtime queries" {
  let hsm : @hsm.HSM[QueryState, QueryEvent, Unit] = @hsm.HSM::new(
    QueryState::Root,
    (),
  )
  hsm.add_state(
    QueryState::Root,
    parent=QueryState::Left,
    initial_child=QueryState::Left,
  )
  hsm.add_state(
    QueryState::Left,
    parent=QueryState::Root,
    initial_child=QueryState::Root,
  )

  debug_inspect(hsm.get_path_to_root(QueryState::Root), content="[Root, Left]")
  debug_inspect(hsm.resolve_initial_leaf(QueryState::Root), content="Root")
  inspect(
    hsm.is_descendant(QueryState::Root, QueryState::Right),
    content="false",
  )
}
