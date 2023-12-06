(* DEPRECATED: TODO Delete/*)
let project_dir_exists = Fs_extra.existsSync

(* DEPRECATED: TODO Delete/*)
let project_dir_is_empty dir = Fs_extra.readdirSync dir |> Array.length = 0
let exists = Fs_extra.existsSync
let dir_is_empty dir = Fs_extra.readdirSync dir |> Array.length = 0

(* DEPRECATED: TODO Delete/*)

let base_template_dir =
  Node.Path.join [| [%mel.raw "__dirname"]; ".."; "templates"; "base" |]
;;

let copy_base_dir ?(overwrite : [> `Clear | `Overwrite ] option) dir =
  try
    match overwrite with
    | None -> Ok (Fs_extra.copySync base_template_dir dir)
    | Some overwrite ->
        if overwrite = `Clear then Fs_extra.emptyDirSync dir;
        Ok (Fs_extra.copySync base_template_dir dir)
  with exn ->
    Error
      (Printf.sprintf {js|Failed to create directory %s: %s|js} dir
         (Printexc.to_string exn))
;;

(* TODO: Rename shit and keep your fn defintions consistent *)
let copy_file ~dest file_path = Fs_extra.copySync file_path dest

(* DEPRECATED - TODO: Delete *)
let create_dir ?(overwrite : [> `Clear | `Overwrite ] option) dir =
  try
    match overwrite with
    | None -> Ok (Fs_extra.copySync base_template_dir dir)
    | Some overwrite ->
        if overwrite = `Clear then Fs_extra.emptyDirSync dir;
        Ok (Fs_extra.copySync base_template_dir dir)
  with exn ->
    Error
      (Printf.sprintf {js|Failed to create directory %s: %s|js} dir
         (Printexc.to_string exn))
;;

let get_template_file_names dir =
  Fs_extra.readdirSync dir |> Array.to_list
  |> List.filter_map (fun file_name ->
         if Js.String.endsWith ".tmpl" file_name then
           Some (Node.Path.join [| dir; file_name |])
         else None)
;;

let read_template ~dir file_name =
  let file_path = Node.Path.join [| dir; file_name |] in
  try Ok (Fs_extra.readFileSync file_path `utf8)
  with exn ->
    Error
      (Printf.sprintf {js|Failed to read file %s from %s: %s|js} file_name
         (Node.Process.cwd ()) (Printexc.to_string exn))
;;

let write_template ~dir file_name content =
  try
    let new_file_name = String.sub file_name 0 (String.length file_name - 5) in
    let new_file_path = Node.Path.join [| dir; new_file_name |] in
    Fs_extra.writeFileSync new_file_path content `utf8;
    let template_file_path = Node.Path.join [| dir; file_name |] in
    Fs_extra.removeSync template_file_path;
    Ok ()
  with exn ->
    Error
      (Printf.sprintf {js|Failed to write file %s: %s|js} file_name
         (Printexc.to_string exn))
;;
