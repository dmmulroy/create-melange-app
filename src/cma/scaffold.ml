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

    (** Check if the template exists in the base directory or in an extension directory.
        If it does not exist, fail. *)
    let validate () =
      let template_path = Node.Path.join [| base_dir; M.name |] in
      let template_exists = Fs.exists template_path in
      if not template_exists then
        failwith @@ Printf.sprintf "Template %s does not exist" template_path
        (* Result.error
           @@ Printf.sprintf "Template %s does not exist" template_path *)
      else Ok ()
    ;;

    let name = M.name

    let compile template =
      let@ _ = validate () in
      let dir = dir_to_string M.dir in
      let name = M.name in
      let json = M.to_json template in
      let@ contents = Fs.read_template ~dir name in
      let template = Handlebars.compile contents () in
      let compiled_contents = template json () in
      Fs.write_template ~dir name compiled_contents
    ;;
  end
end

module Package_json_template = Template.Make (struct
  type t = Package_json.t

  let name = "pakage.json.tmpl"
  let dir = `Base
  let to_json = Package_json.to_json
end)

module Context = struct
  type t = {
    configuration : Configuration.t;
    templates : (module Template.S) String_map.t;
    pkg_json : Package_json.t;
  }

  let make configuration =
    let templates =
      String_map.empty
      |> String_map.add Package_json_template.name
           (module Package_json_template : Template.S)
    in
    { configuration; templates; pkg_json = Package_json.empty }
  ;;

  let set_pkg_json pkg_json ctx = { ctx with pkg_json }
end

(* 1. Copy base directory - Done
   2. Check if any configuration options require extensions (e.g. webpack, vite)
      For each extension:
      2.1. Copy any files from the extension directory if required
      2.2. Extend any existing templates (TODO: How do we relate an extension to a template?)
      3. Compile templates
   4. Run any actions(?) (e.g. npm install, opam init, opam install) *)

let copy_base_dir (ctx : Context.t) =
  Fs.copy_base_dir ?overwrite:ctx.configuration.overwrite ctx.configuration.name
;;

let handle_webpack (ctx : Context.t) =
  List.iter (Fs.copy_file ~dest:ctx.configuration.name) Webpack.files;
  let ctx' =
    Webpack.dev_dependencies
    |> List.fold_left (Fun.flip Package_json.add_dependency) ctx.pkg_json
    |> (Fun.flip Context.set_pkg_json) ctx
  in
  Webpack.scripts
  |> List.fold_left (Fun.flip Package_json.add_script) ctx.pkg_json
  |> (Fun.flip Context.set_pkg_json) ctx'
  |> Result.ok
;;

let handle_vite_config = Ok ()

let handle_extensions (ctx : Context.t) =
  match ctx.configuration.bundler with
  | Webpack -> handle_webpack ctx
  | Vite -> Ok ctx
  | None -> Ok ctx
;;

(*
   let run (config : Configuration.t) =
     let ctx = Context.make config.name in
     let copy_base_dir = copy_base_dir ctx in
     let handle_extensions = handle_extensions ctx in
     let compile_templates = compile_templates ctx in
     let run_actions = run_actions ctx in
     Ok ()
   ;;
*)

let run (config : Configuration.t) =
  let ctx = Context.make config in
  let@ _ = copy_base_dir ctx in
  let@ _ = handle_extensions ctx in
  Ok ()
;;
