type child_process

external exec :
  string ->
  Node.Child_process.option ->
  (* TODO: stdout and stderr may be buffers *)
  (([ `error of exn | `null of 'a Js.Null.t [@mel.unwrap] ] ->
   stdout:string ->
   stderr:string ->
   unit)
  [@mel.uncurry]) ->
  (* TODO: Figure out if this is okay as a return type *)
  unit = "exec"
[@@mel.module "child_process"]

let async_exec string child_process_option =
  Js.Promise.make (fun ~resolve ~reject ->
      exec string child_process_option (fun error ~stdout ~stderr:_ ->
          match error with
          | `error e -> reject e [@u]
          | `null _ -> resolve stdout [@u]))
;;
