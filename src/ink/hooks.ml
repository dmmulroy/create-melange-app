type use_input_options = {
  is_active : bool option; [@optional] [@mel.as "isActive"]
}
[@@deriving abstract]

external use_input :
  ((input:string -> key:Key.t -> unit)[@mel.uncurry]) ->
  options:use_input_options ->
  unit = "useInput"
[@@mel.module "ink"]

type use_app_return = { exit : unit -> Error.t } [@@deriving abstract]

external use_app : unit -> use_app_return = "useApp" [@@mel.module "ink"]
