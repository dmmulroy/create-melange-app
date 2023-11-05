module Instance = struct
  type t
  type error

  external render : React.element -> t = "render" [@@mel.send.pipe: t]
  external cleanup : unit -> unit = "cleanup" [@@mel.send.pipe: t]
  external clear : unit -> unit = "clear" [@@mel.send.pipe: t]

  external wait_until_exit : unit -> unit Js.Promise.t = "waitUntilExit"
  [@@mel.send.pipe: t]

  (* TODO: Hide via mli *)
  external unmount' :
    ([ `Error of error | `Int of int | `Null of 'null Js.null_undefined ]
    [@mel.unwrap]) ->
    unit = "unmount"
  [@@mel.send.pipe: t]

  type unmount_error = Error of error | Int of int | Null

  let unmount = function
    | Error e -> unmount' (`Error e)
    | Int i -> unmount' (`Int i)
    | Null -> unmount' (`Null Js.Nullable.null)

  let rerender = render
end

module Text = struct
  external make : color:string -> children:React.element -> React.element
    = "Text"
  [@@mel.module "ink"] [@@react.component]
end

type write_stream
type read_stream

type render_options = {
  stdout : write_stream option; [@optional]
  stdin : read_stream option; [@optional]
  stderr : write_stream option; [@optional]
  debug : bool option; [@optional]
  exit_on_ctrl_c : bool option; [@optional]
  patch_console : bool option; [@optional]
}
[@@deriving abstract]

external render : React.element -> Instance.t = "render" [@@mel.module "ink"]
