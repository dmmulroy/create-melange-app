[@@@ocaml.warning "-32"]

open Bindings

let ensureDir path =
  path |> Fs_extra.ensureDir |> Promise.of_js_promise
  |> Promise.map (Fun.const true)
  |> Promise.catch (fun _ -> Promise.resolve false)
;;

let ensureFile path =
  path |> Fs_extra.ensureFile |> Promise.of_js_promise
  |> Promise.map (Fun.const true)
  |> Promise.catch (fun _ -> Promise.resolve false)
;;

let exists path =
  path |> Fs_extra.exists |> Promise_result.of_js_promise
  |> Promise_result.catch Promise_result.resolve_error
;;

let dir_is_empty dir = Fs_extra.readdirSync dir |> Array.length = 0

let base_template_dir =
  Node.Path.join
    [|
      Nodejs.Util.__dirname [%mel.raw "import.meta.url"];
      "..";
      "templates";
      "base";
    |]
;;

let create_project_directory ?(overwrite : [< `Clear | `Overwrite ] option) dir
    =
  exists dir
  |. Promise_result.bind (fun exists ->
         if exists then
           match overwrite with
           | Some `Clear ->
               Fs_extra.emptyDir dir |> Promise_result.of_js_promise
           | Some `Overwrite -> Promise_result.resolve_ok ()
           | _ -> assert false
         else Fs_extra.mkdir dir |> Promise_result.of_js_promise)
  |> Promise_result.catch Promise_result.resolve_error
  |> Promise_result.map_error (Fun.const "Failed to create project directory")
;;

let copy_base_project dir =
  Fs_extra.copy base_template_dir dir
  |> Promise_result.of_js_promise
  |> Promise_result.catch Promise_result.resolve_error
  |> Promise_result.map_error
       (Fun.const "Failed to copy base template directory")
;;

let copy_base_project_directory dir =
  Fs_extra.copy base_template_dir dir
  |> Js.Promise.then_ (fun () -> Js.Promise.resolve (Ok ()))
  |> Js.Promise.catch (fun _exn ->
         Js.Promise.resolve
           (Error (Printf.sprintf {js|Failed to create directory %s|js} dir)))
;;

let copy_base_dir ?(overwrite : [> `Clear | `Overwrite ] option) dir =
  let promise =
    match overwrite with
    | None -> Fs_extra.copy base_template_dir dir
    | Some overwrite ->
        let promise =
          if overwrite = `Clear then Fs_extra.emptyDir dir
          else Js.Promise.resolve ()
        in
        Js.Promise.then_ (fun () -> Fs_extra.copy base_template_dir dir) promise
  in
  promise
  |> Js.Promise.then_ (fun () -> Js.Promise.resolve (Ok ()))
  (* TODO: Open issue on Melange repo for improving Js.Promise.error *)
  |> Js.Promise.catch (fun _exn ->
         Js.Promise.resolve
           (Error (Printf.sprintf {js|Failed to create directory %s|js} dir)))
;;

type exn += Fs_extra_error of string

let copy_file_sync ~dest file_path =
  try Fs_extra.copySync file_path dest
  with exn ->
    raise
      (Fs_extra_error
         (Printf.sprintf {js|Failed to copy file %s to %s: %s|js} file_path dest
            (Printexc.to_string exn)))
;;

let copy_file ~dest file_path =
  Fs_extra.copy file_path dest
  |> Promise_result.of_js_promise
  |> Promise_result.catch Promise_result.resolve_error
  |> Promise_result.map_error
       (Fun.const
          (Printf.sprintf {js|Failed to copy file %s to %s|js} file_path dest))
;;

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
  try
    let contents = Fs_extra.readFileSync file_path in
    contents
  with exn ->
    Error
      (Printf.sprintf {js|Failed to read template %s from %s: %s|js} file_name
         (Node.Process.cwd ()) (Printexc.to_string exn))
;;

let validate_template_exists ~dir file_name =
  let open Promise.Syntax.Let in
  let file_path = Node.Path.join [| dir; file_name |] in
  let* template_exists = ensureFile file_path in
  if not template_exists then
    Promise_result.resolve_error
    @@ Printf.sprintf "Template %s does not exist at %s" file_name file_path
  else Promise_result.resolve_ok ()
;;

(* TODO: Make async *)
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

let trim_trailing_slash str =
  if String.ends_with ~suffix:"/" str then
    String.sub str 0 (String.length str - 1)
  else str
;;

let parse_project_name_and_dir (str : string) =
  let trimmed = trim_trailing_slash str in
  if String.equal trimmed "." then
    let name = [| trimmed |] |> Nodejs.Path.resolve |> Nodejs.Path.basename in
    let directory = [| Nodejs.Process.cwd () |] |> Nodejs.Path.resolve in
    (name, directory)
  else
    let name = [| trimmed |] |> Nodejs.Path.resolve |> Nodejs.Path.basename in
    let directory =
      [| trimmed; name |] |> Nodejs.Path.resolve |> Nodejs.Path.dirname
    in
    (name, directory)
;;
