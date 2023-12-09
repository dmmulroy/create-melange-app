open Common
open Syntax
open! Let
module String_map = Map.Make (String)

let copy_base_dir (ctx : Context.t) =
  Fs.copy_base_dir ?overwrite:ctx.configuration.overwrite ctx.configuration.name
  |> Result.map (fun _ -> ctx)
;;

(* TODO: Think about a potential helper for mapping template values in the context *)
let handle_webpack (ctx : Context.t) =
  (* Copy webpack files *)
  List.iter
    (fun file_path ->
      let file_name = Node.Path.basename file_path in
      let dest = Node.Path.join [| ctx.configuration.name; "/"; file_name |] in
      Fs.copy_file ~dest file_path)
    Webpack.files;
  let@ pkg_json =
    Hmap.find Template.Package_json_template.key ctx.template_values
    |> Option.to_result
         ~none:"package.json template not found in scaffold context"
  in
  (* Add dependencies to package.json *)
  let pkg_json =
    Webpack.dev_dependencies
    |> List.fold_left (Fun.flip Package_json.add_dependency) pkg_json
  in
  (* Add scripts to package.json *)
  let pkg_json =
    Webpack.scripts
    |> List.fold_left (Fun.flip Package_json.add_script) pkg_json
  in
  Ok
    {
      ctx with
      template_values =
        Hmap.add Template.Package_json_template.key pkg_json ctx.template_values;
    }
;;

let handle_vite (ctx : Context.t) =
  (* Copy vite files *)
  List.iter
    (fun file_path ->
      let file_name = Node.Path.basename file_path in
      let dest = Node.Path.join [| ctx.configuration.name; "/"; file_name |] in
      Fs.copy_file ~dest file_path)
    Vite.files;
  let@ pkg_json =
    Hmap.find Template.Package_json_template.key ctx.template_values
    |> Option.to_result
         ~none:"package.json template not found in scaffold context"
  in
  (* Add dependencies to package.json *)
  let pkg_json =
    Vite.dev_dependencies
    |> List.fold_left (Fun.flip Package_json.add_dependency) pkg_json
  in
  (* Add scripts to package.json *)
  let pkg_json =
    Vite.scripts |> List.fold_left (Fun.flip Package_json.add_script) pkg_json
  in
  Ok
    {
      ctx with
      template_values =
        Hmap.add Template.Package_json_template.key pkg_json ctx.template_values;
    }
;;

let handle_git (ctx : Context.t) =
  if not ctx.configuration.initialize_git then Ok ctx
  else
    (* Copy git files *)
    let () =
      Git.files
      |> List.iter (fun file_path ->
             let file_name = Node.Path.basename file_path in
             let dest =
               Node.Path.join [| ctx.configuration.name; "/"; file_name |]
             in
             Fs.copy_file ~dest file_path)
    in
    (* Run the git action (e.g. intialize and stage files)*)
    Git.run ctx |> Result.ok |> Result.map (fun _ -> ctx)
;;

let handle_npm (ctx : Context.t) =
  if not ctx.configuration.initialize_npm then Ok ctx
  else Npm.run ctx |> Result.ok |> Result.map (fun _ -> ctx)
;;

let handle_bundler (ctx : Context.t) =
  match ctx.configuration.bundler with
  | Webpack -> handle_webpack ctx
  | Vite -> handle_vite ctx
  | None -> Ok ctx
;;

let fold_compilation_results (ctx : Context.t) (acc : (unit, string) result)
    (_, (module Template : Template.S)) =
  if Result.is_error acc then acc
  else
    let template_value = Hmap.find Template.key ctx.template_values in
    let dir = Node.Path.join [| "./"; ctx.configuration.name |] in
    match template_value with
    | None ->
        Error
          (Printf.sprintf "A value for Template %s was not found" Template.name)
    | Some value -> Template.compile ~dir value
;;

let compile_template (ctx : Context.t) =
  String_map.to_list ctx.templates
  |> List.fold_left (fold_compilation_results ctx) (Ok ())
  |> Result.map (fun _ -> ctx)
;;

let bind_result = Fun.flip Result.bind

let run (config : Configuration.t) =
  Context.make config |> copy_base_dir |> bind_result handle_bundler
  |> bind_result compile_template
  |> bind_result handle_npm |> bind_result handle_git
  |> Result.map (fun _ -> ())
;;
