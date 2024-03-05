type dynamic = Dynamic : 'a -> dynamic [@@unboxed]

type builtin_helpers = {
  helpers_missing : bool; [@mel.as "helpersMissing"]
  block_helper_missing : bool; [@mel.as "blockHelperMissing"]
  each : bool;
  if_ : bool; [@mel.as "if"]
  unless : bool;
  with_ : bool; [@mel.as "with"]
  log : bool;
  lookup : bool;
}

type custom_helpers = bool Js.Dict.t
type known_helpers = Builtin of builtin_helpers | Custom of custom_helpers

type t = {
  data : bool option; [@mel.optional]
  compat : bool option; [@mel.optional]
  known_helpers : known_helpers option; [@mel.optional]
  known_helpers_only : bool option; [@mel.optional]
  no_escape : bool option; [@mel.optional]
  strict : bool option; [@mel.optional]
  assume_objects : bool option; [@mel.optional]
  prevent_indent : bool option; [@mel.optional]
  ignore_standalone : bool option; [@mel.optional]
  explicit_partial_context : bool option; [@mel.optional]
}
[@@deriving abstract]
