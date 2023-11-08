type dynamic = Dynamic : 'a -> dynamic [@@unboxed]
type command_option
type argument

(* TODO: Turn this into a monad *)
type t = {
  args : string array;
  processed_args : dynamic array; [@mel.as "processedArgs"]
  commands : t array;
  options : command_option array;
  registered_arguments : argument array; [@mel.as "registeredArgs"]
  parent : t option;
}

external program : ?name:string -> unit -> t = "Command"
[@@mel.new] [@@mel.module "commander"]

external version : t -> string = "version"

external set_version :
  version:string -> ?flags:string -> ?description:string -> t = "version"
[@@mel.send.pipe: t]
