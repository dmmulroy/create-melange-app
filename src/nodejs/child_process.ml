type child_process

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
          match Js.Null_undefined.toOption error with
          | Some e -> reject e [@u]
          | None -> resolve stdout [@u]))
;;
