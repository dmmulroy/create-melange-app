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
  data : bool option; [@optional]
  compat : bool option; [@optional]
  known_helpers : known_helpers option; [@optional]
  known_helpers_only : bool option; [@optional]
  no_escape : bool option; [@optional]
  strict : bool option; [@optional]
  assume_objects : bool option; [@optional]
  prevent_indent : bool option; [@optional]
  ignore_standalone : bool option; [@optional]
  explicit_partial_context : bool option; [@optional]
}
[@@deriving abstract]
