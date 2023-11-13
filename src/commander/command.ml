type dynamic = Dynamic : 'a -> dynamic [@@unboxed]

type command_option = {
  hidden : bool option; [@optional]
  is_default : bool option; [@optional] [@mel.as "isDefault"]
  executable_file : string option; [@optional] [@mel.as "executableFile"]
}
[@@deriving abstract]

type t = {
  args : string array;
  processed_args : dynamic array; [@mel.as "processedArgs"]
  commands : string array;
  options : Opt.t array;
  registered_arguments : Argument.t array; [@mel.as "registeredArgs"]
  parent : t option;
}

(* TODO: Create odoc comments for these functions *)
external make : string -> t = "Command" [@@mel.new] [@@mel.module "commander"]
external version : t -> string = "version"

external set_version : string -> ?flags:string -> ?description:string -> t
  = "version"
[@@mel.send.pipe: t]

external set_description : string -> t = "description" [@@mel.send.pipe: t]
external set_name : string -> t = "name" [@@mel.send.pipe: t]

external command : name_and_args:string -> ?options:command_option array -> t
  = "command"
[@@mel.send.pipe: t]

external executable_command :
  name_and_args:string ->
  description:string ->
  ?options:command_option array ->
  t = "command"
[@@mel.send.pipe: t]

external create_command : string -> t = "createCommand"
[@@mel.send.pipe: t]
(** Factory routine to create a new unattached command.*)

external add_command : ?options:command_option array -> t -> t = "addCommand"
[@@mel.send.pipe: t]
(** Add a prepared subcommand. *)

external create_argument : name:string -> ?description:string -> Argument.t
  = "createArgument"
(** Factory routine to create a new unattached argument.*)

external argument :
  name:string -> ?description:string -> ?default_value:Argument.value -> t
  = "argument"
[@@mel.send.pipe: t]
(**
   * Define argument syntax for command.
   *
   * The default is that the argument is required, and you can explicitly
   * indicate this with <> around the name. Put [] around the name for an optional argument.
   *)

external argument_extended :
  name:string ->
  ?description:string ->
  fn:((value:string -> previous:Argument.value -> Argument.value)[@mel.uncurry]) ->
  ?default_value:Argument.value ->
  t = "argument"
[@@mel.send.pipe: t]
(**
   * Define argument syntax for command.
   *
   * The default is that the argument is required, and you can explicitly
   * indicate this with <> around the name. Put [] around the name for an optional argument.
   *)

external add_argument : Argument.t -> t = "addArgument"
[@@mel.send.pipe: t]
(** Define argument syntax for command, adding a prepared argument. *)

external arguments : names:string -> t = "argument"
[@@mel.send.pipe: t]
(** Override default decision whether to add implicit help command. *)

external add_action :
  ('a -> [ `Void of unit | `Promise_void of unit Js.Promise.t ]) -> t = "action"
[@@mel.send.pipe: t]
(** Register callback `fn` for the command.*)

external add_action2 :
  ('a -> 'b -> [ `Void of unit | `Promise_void of unit Js.Promise.t ]) -> t
  = "action"
[@@mel.send.pipe: t]
(** Register callback `fn` for the command.*)

external add_action3 :
  ('a -> 'b -> 'c -> [ `Void of unit | `Promise_void of unit Js.Promise.t ]) ->
  t = "action"
[@@mel.send.pipe: t]
(** Register callback `fn` for the command.*)

external add_help_command :
  enable_or_name_and_args:[ `Bool of bool | `String of string ] ->
  ?description:string ->
  t = "addHelpCommand"
[@@mel.send.pipe: t]
(** Override default decision whether to add implicit help command. *)

external option :
  flags:string -> ?description:string -> ?default_value:Opt.value -> t
  = "option"
[@@mel.send.pipe: t]
(**
   * Define option with `flags`, `description`, and optional argument parsing function or `defaultValue` or both.
   *
   * The `flags` string contains the short and/or long flags, separated by comma, a pipe or space. A required
   * option-argument is indicated by `<>` and an optional option-argument by `[]`.
   *)

external option_extended :
  flags:string ->
  description:string ->
  parse_arg:((value:string -> previous:Opt.value -> Opt.value)[@mel.uncurry]) ->
  ?default_value:Opt.value ->
  t = "option"
[@@mel.send.pipe: t]
(**
   * Define option with `flags`, `description`, and optional argument parsing function or `defaultValue` or both.
   *
   * The `flags` string contains the short and/or long flags, separated by comma, a pipe or space. A required
   * option-argument is indicated by `<>` and an optional option-argument by `[]`.
   *)

type parse_options

external parse : ?argv:string array -> ?options:parse_options -> t = "parse"
[@@mel.send.pipe: t]
(** Parse `argv`, setting options and invoking commands when defined. *)

type option_values

external opts : unit -> option_values = "opts"
[@@mel.send.pipe: t]
(** Return options values, excluding the implicit help option. *)
