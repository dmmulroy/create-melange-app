let project_dir_exists = Fs_extra.existsSync
let project_dir_is_empty dir = Fs_extra.readdirSync dir |> Array.length = 0

let template_dir =
  Node.Path.join [| [%mel.raw "__dirname"]; ".."; "templates"; "base" |]
;;

let create_dir ?(overwrite : [> `Clear | `Overwrite ] option) dir =
  try
    match overwrite with
    | None -> Ok (Fs_extra.copySync template_dir dir)
    | Some overwrite ->
        if overwrite = `Clear then Fs_extra.emptyDirSync dir;
        Ok (Fs_extra.copySync template_dir dir)
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

let read_template file_path =
  try Ok (Fs_extra.readFileSync file_path `utf8)
  with exn ->
    Error
      (Printf.sprintf {js|Failed to read file %s from %s: %s|js} file_path
         (Node.Process.cwd ()) (Printexc.to_string exn))
;;

let write_template file_name content =
  try
    let new_file_name = String.sub file_name 0 (String.length file_name - 5) in
    Fs_extra.writeFileSync new_file_name content `utf8;
    Fs_extra.removeSync file_name;
    Ok ()
  with exn ->
    Error
      (Printf.sprintf {js|Failed to write file %s: %s|js} file_name
         (Printexc.to_string exn))
;;
