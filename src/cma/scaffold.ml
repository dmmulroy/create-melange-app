open Common
open Syntax
open Let
(* 1. Copy base directory - Done
   2. Check if any configuration options require extensions (e.g. webpack, vite)
      For each extension:
      2.1. Copy any files from the extension directory if required
      2.2. Extend any existing templates (TODO: How do we relate an extension to a template?)
      3. Compile templates
   4. Run any actions(?) (e.g. npm install, opam init, opam install) *)

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
        Result.error
        @@ Printf.sprintf "Template %s does not exist" template_path
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

let copy_base_dir (config : Configuration.t) =
  Fs.copy_dir ?overwrite:config.overwrite config.name
;;

let handle_webpack _config = Ok ()
let handle_vite _config = Ok ()

let handle_extensions (config : Configuration.t) =
  match config.bundler with
  | Webpack -> handle_webpack config
  | Vite -> handle_vite config
  | None -> Ok ()
;;

(* module Context = struct
     type 'a t = {
       value : 'a;
       templates : (module Template.S) String_map.t;
       extensions : (module Extension.S) String_map.t;
     }

     let make ?(templates = String_map.empty) ?(extensions = String_map.empty)
         value =
       { value; templates; extensions }
     ;;

     let find_template_opt ~name ctx = String_map.find_opt name ctx.templates
     let find_extension_opt ~name ctx = String_map.find_opt name ctx.extensions

     let register_template ~name ~template ctx =
       { ctx with templates = String_map.add name template ctx.templates }
     ;;

     let compile_template _ctx template =
       let module Template = (val template : Template.S) in
       let tmpl = Template.base in
       let@ () = Template.compile tmpl in
       Ok ()
     ;;
   end

   let _ =
     Context.make "string ctx"
     |> Context.register_template ~name:"package.json"
          ~template:(module Package_json)
     |> Context.register_template ~name:"dune-project"
          ~template:(module Dune_project)
   ;; *)
