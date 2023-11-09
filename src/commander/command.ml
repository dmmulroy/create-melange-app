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
  options : Commander_option.t array;
  registered_arguments : Argument.t array; [@mel.as "registeredArgs"]
  parent : t option;
}

(* TODO: Create odoc comments for these functions *)
external program : ?name:string -> unit -> t = "Command"
[@@mel.new] [@@mel.module "commander"]

external version : t -> string = "version"

external set_version :
  version:string -> ?flags:string -> ?description:string -> t = "version"
[@@mel.send.pipe: t]

external command : name_and_args:string -> ?options:command_option array -> t
  = "command"
[@@mel.send.pipe: t]

external executable_command :
  name_and_args:string ->
  description:string ->
  ?options:command_option array ->
  t = "command"
[@@mel.send.pipe: t]

external create_command : name:string -> t = "createCommand"
(** Factory routine to create a new unattached command.*)

external add_command : cmd:t -> ?options:command_option array -> t
  = "addCommand"
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
  flags:string ->
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

external arguments : names:string -> t = "argument"
[@@mel.send.pipe: t]
(** Override default decision whether to add implicit help command. *)

external add_help_command :
  enable_or_name_and_args:[ `bool of bool | `string of string ] ->
  ?description:string ->
  t = "addHelpCommand"
[@@mel.send.pipe: t]
(** Override default decision whether to add implicit help command. *)

external option :
  flags:string ->
  ?description:string ->
  ?default_value:Commander_option.value ->
  t = "option"
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
  parse_arg:
    ((value:string -> previous:Commander_option.value -> Commander_option.value)
    [@mel.uncurry]) ->
  ?default_value:Commander_option.value ->
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
