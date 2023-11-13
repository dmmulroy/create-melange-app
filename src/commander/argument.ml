type value = [ `Bool of bool | `String of string | `Strings of string array ]

type t = {
  description : string;
  required : bool;
  variadic : bool;
  default_value : value option; [@mel.as "defaultValue"]
  default_value_description : string option; [@mel.as "defaultValueDescription"]
  arg_choices : string array option; [@optional] [@mel.as "argChoices"]
}
[@@deriving abstract]

external make : name:string -> ?description:string -> unit -> t = "Argument"
[@@mel.new] [@@mel.module "commander"]

external name : unit -> string = "name"
[@@mel.send.pipe: t]
(** Return argument name. *)

external default : value:value -> ?description:string -> t = "default"
[@@mel.send.pipe: t]
(** Set the default value, and optionally supply the description to be displayed in the help. *)

external arg_parser :
  fn:((value:string -> previous:value -> value)[@mel.uncurry]) -> t
  = "argParser"
[@@mel.send.pipe: t]
(** Set the custom handler for processing CLI command arguments into argument values. *)

external choices : values:string array -> t = "choices"
[@@mel.send.pipe: t]
(** Only allow argument value to be one of choices. *)

external arg_required : t = "argRequired"
[@@mel.send.pipe: t]
(** Make argument required. *)

external arg_optional : t = "argOptional"
[@@mel.send.pipe: t]
(** Make argument optional. *)
