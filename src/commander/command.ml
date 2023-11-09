type dynamic = Dynamic : 'a -> dynamic [@@unboxed]
type argument

type t = {
  args : string array;
  processed_args : dynamic array; [@mel.as "processedArgs"]
  commands : string array;
  options : Commander_option.t array;
  registered_arguments : argument array; [@mel.as "registeredArgs"]
  parent : t option;
}

external program : ?name:string -> unit -> t = "Command"
[@@mel.new] [@@mel.module "commander"]

external version : t -> string = "version"

external set_version :
  version:string -> ?flags:string -> ?description:string -> t = "version"
[@@mel.send.pipe: t]

(* command(nameAndArgs: string, opts?: CommandOptions): ReturnType<this['createCommand']>; *)
(* external command : ~name_and_args:string -> ?options: *)
