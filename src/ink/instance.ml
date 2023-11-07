type t

external render : React.element -> t = "render" [@@mel.send.pipe: t]
external cleanup : unit -> unit = "cleanup" [@@mel.send.pipe: t]
external clear : unit -> unit = "clear" [@@mel.send.pipe: t]

external wait_until_exit : unit -> unit Js.Promise.t = "waitUntilExit"
[@@mel.send.pipe: t]

(* TODO: Hide via mli *)
external unmount' :
  ([ `Error of Error.t | `Int of int | `Null of 'null Js.null_undefined ]
  [@mel.unwrap]) ->
  unit = "unmount"
[@@mel.send.pipe: t]

type unmount_error = Error of Error.t | Int of int | Null

let unmount = function
  | Error e -> unmount' (`Error e)
  | Int i -> unmount' (`Int i)
  | Null -> unmount' (`Null Js.Nullable.null)

let rerender = render
