external exec :
  string ->
  Node.Child_process.option ->
  (* TODO: stdout and stderr may be buffers *)
  ((error:exn Js.nullable -> stdout:string -> stderr:string -> unit)
  [@mel.uncurry]) ->
  (* TODO: Figure out if this is okay as a return type *)
  unit = "exec"
[@@mel.module "node:child_process"]

let async_exec string child_process_option =
  Js.Promise.make (fun ~resolve ~reject ->
      exec string child_process_option (fun ~error ~stdout ~stderr:_ ->
          match Js.Nullable.toOption error with
          | Some e -> reject e [@u]
          | None -> resolve stdout [@u]))
;;

module Child_process = struct
  type t
  type stream

  external stderr : t -> stream = "stderr" [@@mel.get]
  external stdin : t -> stream = "stdin" [@@mel.get]

  external on_data : (_[@mel.as "data"]) -> (string -> unit) -> unit = "on"
  [@@mel.send.pipe: stream]

  external on_close : (_[@mel.as "close"]) -> (int -> unit) -> unit = "on"
  [@@mel.send.pipe: t]

  external on_error : (_[@mel.as "error"]) -> (Js.Exn.t -> unit) -> unit = "on"
  [@@mel.send.pipe: t]

  external spawn : string -> string array -> t = "spawn"
  [@@mel.module "node:child_process"]
end
