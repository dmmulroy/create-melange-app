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
    val compile : t -> (unit, string) result
  end

  module Config = struct
    module type S = sig
      type t

      val dir : [ `Base | `Extension of string ]
      val name : string
      val to_json : t -> Js.Json.t
    end
  end

  module Make (M : Config.S) : S with type t = M.t = struct
    type t = M.t

    let key = Hmap.Key.create ()

    let validate () =
      let template_path = Node.Path.join [| "./foobar"; M.name |] in
      let template_exists = Fs.exists template_path in
      if not template_exists then
        Result.error
        @@ Printf.sprintf "Template %s does not exist" template_path
      else Ok ()
    ;;

    let name = M.name

    let compile value =
      let@ _ = validate () in
      let dir = dir_to_string M.dir in
      let name = M.name in
      let json = M.to_json value in
      let@ contents = Fs.read_template ~dir name in
      let template = Handlebars.compile contents () in
      let compiled_contents = template json () in
      Fs.write_template ~dir name compiled_contents
    ;;
  end
end

module Package_json_template = Template.Make (struct
  type t = Package_json.t

  let name = "package.json.tmpl"
  let dir = `Base
  let to_json = Package_json.to_json
end)

module Dune_project_template = Template.Make (struct
  type t = Dune_project.t

  let name = "dune-project.tmpl"
  let dir = `Base
  let to_json _ = Js.Json.null
end)

module Context = struct
  type t = {
    configuration : Configuration.t;
    (* Template name -> Template module *)
    templates : (module Template.S) String_map.t;
    (* Template key -> Template value*)
    template_values : Hmap.t;
  }

  let make configuration =
    let template_values =
      Hmap.empty |> Hmap.add Package_json_template.key Package_json.empty
      (* |> Hmap.add Dune_project_template.key Dune_project.empty *)
    in
    let templates =
      String_map.empty
      |> String_map.add Package_json_template.name
           (module Package_json_template : Template.S)
      (* |> String_map.add Dune_project_template.name *)
      (*      (module Dune_project_template : Template.S) *)
    in
    { configuration; templates; template_values }
  ;;
end

let copy_base_dir (ctx : Context.t) =
  Fs.copy_base_dir ?overwrite:ctx.configuration.overwrite ctx.configuration.name
;;

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

let handle_vite_config ctx = Ok ctx

let handle_extensions (ctx : Context.t) =
  match ctx.configuration.bundler with
  | Webpack -> handle_webpack ctx
  | Vite -> Ok ctx
  | None -> Ok ctx
;;

let fold_compilation_results (ctx : Context.t) (acc : (unit, string) result)
    (_, (module Template : Template.S)) =
  if Result.is_error acc then acc
  else
    let template_value = Hmap.find Template.key ctx.template_values in
    match template_value with
    | None ->
        Error
          (Printf.sprintf "A value for Template %s was not found" Template.name)
    | Some value -> Template.compile value
;;

let compile_template (ctx : Context.t) =
  String_map.to_list ctx.templates
  |> List.fold_left (fold_compilation_results ctx) (Ok ())
;;

let run (config : Configuration.t) =
  let ctx = Context.make config in
  let@ _ = copy_base_dir ctx in
  let@ _ = handle_extensions ctx in
  let@ _ = compile_template ctx in
  Ok ()
;;

(* 1. Copy base directory - Done
   2. Check if any configuration options require extensions (e.g. webpack, vite)
      For each extension:
      2.1. Copy any files from the extension directory if required
      2.2. Extend any existing templates (TODO: How do we relate an extension to a template?)
      3. Compile templates
   4. Run any actions(?) (e.g. npm install, opam init, opam install) *)
(*
   let run (config : Configuration.t) =
     let ctx = Context.make config.name in
     let copy_base_dir = copy_base_dir ctx in
     let handle_extensions = handle_extensions ctx in
     let compile_templates = compile_templates ctx in
     let run_actions = run_actions ctx in (* running opam init, npm install, git init*) 
     Ok ()
   ;;
*)
