type value = [ `Bool of bool | `String of string | `Strings of string array ]

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

external make : ?description:string -> string -> t = "Option"
[@@mel.new] [@@mel.module "commander"]

external set_default : ?description:string -> value -> t = "default"
[@@mel.send.pipe: t]
