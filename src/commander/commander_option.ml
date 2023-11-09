type value = [ `bool of bool | `string of string | `strings of string array ]

type t = {
  flags : string;
  description : string;
  required : bool;
  optional : bool;
  variadic : bool;
  mandatory : bool;
  short : string option;
  long : string option;
  negate : bool;
  default_value : value option; [@mel.as "defaultValue"]
  default_value_description : string option; [@mel.as "defaultValueDescription"]
  preset_arg : value option; [@mel.as "presetArg"]
  env_var : string option; [@mel.as "envVar"]
  parse_arg : (value:string -> previous:value -> value) option;
      [@mel.as "parseArg"]
  hidden : bool;
  arg_choices : string array option; [@mel.as "argChoices"]
}

external commander_option : ?flags:string -> ?description:string -> unit -> t
  = "Option"
[@@mel.new] [@@mel.module "commander"]
