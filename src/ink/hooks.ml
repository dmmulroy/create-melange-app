type use_input_options = {
  is_active : bool option; [@optional] [@mel.as "isActive"]
}
[@@deriving abstract]

external use_input :
  ((input:string -> key:Key.t -> unit)[@mel.uncurry]) ->
  options:use_input_options ->
  unit = "useInput"
[@@mel.module "ink"]

type use_app_return = { exit : unit -> Error.t }

external use_app : unit -> use_app_return = "useApp" [@@mel.module "ink"]

type use_stdin_return = {
  stdin : Stream.read;
  is_raw_mode_supported : bool; [@mel.as "isRawModeSupproted"]
}

external use_stdin : unit -> use_stdin_return = "useStdin" [@@mel.module "ink"]

type use_stdout_return = { stdin : Stream.write; write : string -> unit }

external use_stdout : unit -> use_stdout_return = "useStdout"
[@@mel.module "ink"]

type use_stderr_return = { stdin : Stream.write; write : string -> unit }

external use_stderr : unit -> use_stderr_return = "useStderr"
[@@mel.module "ink"]

type use_focus_options = {
  auto_focus : bool; [@mel.as "autoFocus"]
  is_active : bool; [@mel.as "isActive"]
  id : string option; [@optional]
}
[@@deriving abstract]

type use_focus_return = { is_focused : bool [@mel.as "isFocused"] }

external use_focus : ?options:use_focus_options -> unit -> use_focus_return
  = "useFocus"
[@@mel.module "ink"]

type use_focus_manager_return = {
  enable_focus : unit -> unit; [@mel.as "enableFocus"]
  disable_focus : unit -> unit; [@mel.as "disableFocus"]
  focus_next : unit -> unit; [@mel.as "focusNext"]
  focus_previous : unit -> unit; [@mel.as "focusPrevious"]
  focus_id : string -> unit; [@mel.as "focusId"]
}

external use_focus_manager : unit -> use_focus_manager_return
  = "useFocusManager"
[@@mel.module "ink"]
