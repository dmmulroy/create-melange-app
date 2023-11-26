type dynamic = Dynamic : 'a -> dynamic [@@unboxed]

module rec Options : sig
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

  module Runtime : sig
    type 'a t = {
      partial : bool option; [@optional]
      depths : dynamic array option; [@optional]
      helpers : dynamic Js.Dict.t option; [@optional]
      partials : dynamic Template.t Js.Dict.t option; [@optional]
      decorators : dynamic Js.Dict.t option; [@optional]
      data : dynamic option; [@optional]
      block_params : dynamic array option; [@optional] [@mel.as "blockParams"]
      allow_calls_to_helper_missing : bool option;
          [@optional] [@mel.as "allowCallsToHelperMissing"]
      allowed_proto_properties : bool Js.Dict.t option;
          [@optional] [@mel.as "allowedProtoProperties"]
      allowed_proto_methods : bool Js.Dict.t option;
          [@optional] [@mel.as "allowedProtoMethods"]
      allow_proto_properties_by_default : bool option;
          [@optional] [@mel.as "allowProtoPropertiesByDefault"]
      allow_proto_methods_by_default : bool option;
          [@optional] [@mel.as "allowProtoMethodsByDefault"]
    }
    [@@deriving abstract]
  end
end = struct
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

  module Runtime = struct
    type 'a t = {
      partial : bool option; [@optional]
      depths : dynamic array option; [@optional]
      helpers : dynamic Js.Dict.t option; [@optional]
      partials : dynamic Template.t Js.Dict.t option; [@optional]
      decorators : dynamic Js.Dict.t option; [@optional]
      data : dynamic option; [@optional]
      block_params : dynamic array option; [@optional] [@mel.as "blockParams"]
      allow_calls_to_helper_missing : bool option;
          [@optional] [@mel.as "allowCallsToHelperMissing"]
      allowed_proto_properties : bool Js.Dict.t option;
          [@optional] [@mel.as "allowedProtoProperties"]
      allowed_proto_methods : bool Js.Dict.t option;
          [@optional] [@mel.as "allowedProtoMethods"]
      allow_proto_properties_by_default : bool option;
          [@optional] [@mel.as "allowProtoPropertiesByDefault"]
      allow_proto_methods_by_default : bool option;
          [@optional] [@mel.as "allowProtoMethodsByDefault"]
    }
    [@@deriving abstract]
  end
end

and Template : sig
  type 'a delegate = 'a -> ?runtime_options:'a Options.Runtime.t -> string
  type 'a t = String of string | Delegate of 'a delegate
end = struct
  type 'a delegate = 'a -> ?runtime_options:'a Options.Runtime.t -> string
  type 'a t = String of string | Delegate of 'a delegate
end

(* export function registerPartial(name: string, fn: HandlebarsTemplateDelegate): void; *)
(* export function template<T = any>(precompiled: HandlebarsTemplateDelegate<T>, options?: RuntimeOptions): HandlebarsTemplateDelegate<T>; *)

(* export function compile<T = any>(input: any, options?: CompileOptions): HandlebarsTemplateDelegate<T>; *)
external compile :
  string ->
  ?options:Options.t ->
  unit ->
  ('a -> runtime_options:'a Options.Runtime.t option -> unit -> string[@u])
  = "compile"
[@@mel.module "handlebars"]

let compile s ?options () =
  let template = compile s ?options () in
  fun a ?runtime_options () -> (template a ~runtime_options () [@u])
