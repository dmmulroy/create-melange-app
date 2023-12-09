open Common
open Syntax
open Let
module String_map = Map.Make (String)

module Template = struct
  let root_dir = "templates"
  let base_dir = Node.Path.join [| root_dir; "base" |]
  let extensions_dir = Node.Path.join [| root_dir; "extensions" |]
  let dir_to_string = function `Base -> "./" | `Extension dir -> dir

  module type S = sig
    type t

    val key : t Hmap.key
    val name : string
    val compile : dir:string -> t -> (unit, string) result
  end

  module Config = struct
    module type S = sig
      type t

      val name : string
      val to_json : t -> Js.Json.t
    end
  end

  module Make (M : Config.S) : S with type t = M.t = struct
    type t = M.t

    let key = Hmap.Key.create ()
    let name = M.name

    let compile ~dir value =
      let@ _ = Fs.validate_template_exists ~dir M.name in
      let json = M.to_json value in
      let@ contents = Fs.read_template ~dir M.name in
      let template = Handlebars.compile contents () in
      let compiled_contents = template json () in
      Fs.write_template ~dir name compiled_contents
    ;;
  end
end

module Package_json_template = Template.Make (struct
  type t = Package_json.t

  let name = "package.json.tmpl"
  let to_json = Package_json.to_json
end)

module Dune_project_template = Template.Make (struct
  type t = Dune_project.t

  let name = "dune-project.tmpl"
  let to_json = Dune_project.to_json
end)

module Context = struct
  type t = {
    configuration : Configuration.t;
    (* Template name -> Template module *)
    templates : (module Template.S) String_map.t;
    (* Template key -> Template value*)
    template_values : Hmap.t;
  }

  let make (configuration : Configuration.t) =
    let pkg = Package_json.empty |> Package_json.set_name configuration.name in
    let dune_project =
      Dune_project.empty |> Dune_project.set_name configuration.name
    in
    let template_values =
      Hmap.empty
      |> Hmap.add Package_json_template.key pkg
      |> Hmap.add Dune_project_template.key dune_project
    in
    let templates =
      String_map.empty
      |> String_map.add Package_json_template.name
           (module Package_json_template : Template.S)
      |> String_map.add Dune_project_template.name
           (module Dune_project_template : Template.S)
    in
    { configuration; templates; template_values }
  ;;
end

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
    Hmap.find Package_json_template.key ctx.template_values
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
        Hmap.add Package_json_template.key pkg_json ctx.template_values;
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
    Hmap.find Package_json_template.key ctx.template_values
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
        Hmap.add Package_json_template.key pkg_json ctx.template_values;
    }
;;

let handle_extensions (ctx : Context.t) =
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
  Context.make config |> copy_base_dir
  |> bind_result handle_extensions
  |> bind_result compile_template
  |> Result.map (fun _ -> ())
;;
