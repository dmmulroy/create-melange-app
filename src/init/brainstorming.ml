[@@@ocaml.warning "-32"]

open Common
open Syntax
open! Let
module String_map = Map.Make (String)

module Template = struct
  let root_dir = "templates"

  module type S = sig
    type t

    val base : t
    val name : string
    val compile : t -> (unit, string) result
  end

  module Config = struct
    module type S = sig
      type t

      val base : t
      val dir : string
      val name : string
      val map : (t -> t) -> t
      val to_json : t -> Js.Json.t
    end
  end

  module Make (M : Config.S) : S with type t = M.t = struct
    type t = M.t

    let name = M.name
    let base = M.base

    let compile template =
      let dir = M.dir in
      let name = M.name in
      let json = M.to_json template in
      let@ contents = Fs.read_template ~dir name in
      let template = Handlebars.compile contents () in
      let compiled_contents = template json () in
      Fs.write_template ~dir name compiled_contents
    ;;
  end
end

(* module Package_json = Template.Make (struct
     type t = {
       name : string;
       scripts : string String_map.t;
       dependencies : string String_map.t;
       dev_dependencies : string String_map.t;
     }

     let dir = Template.root_dir
     let name = "package.json.tmpl"

     let base =
       {
         name = "";
         scripts = String_map.empty;
         dependencies = String_map.empty;
         dev_dependencies = String_map.empty;
       }
     ;;

     let to_json pkg =
       let obj = Js.Dict.empty () in
       Js.Dict.set obj "name" (Js.Json.string pkg.name);
       let scripts =
         String_map.to_list pkg.scripts
         |> List.map (fun (key, value) -> (key, Js.Json.string value))
         |> Js.Dict.fromList |> Js.Json.object_
       in
       Js.Dict.set obj "scripts" scripts;
       let dependencies =
         String_map.to_list pkg.dependencies
         |> List.map (fun (key, value) -> (key, Js.Json.string value))
         |> Js.Dict.fromList |> Js.Json.object_
       in
       Js.Dict.set obj "dependencies" dependencies;
       let dev_dependencies =
         String_map.to_list pkg.dev_dependencies
         |> List.map (fun (key, value) -> (key, Js.Json.string value))
         |> Js.Dict.fromList |> Js.Json.object_
       in
       Js.Dict.set obj "devDependencies" dev_dependencies;
       Js.Json.object_ obj
     ;;
   end)

   module Dune_project = Template.Make (struct
     type t = { name : string; depends : string option String_map.t }

     let dir = Template.root_dir
     let name = "dune-project.tmpl"
     let base = { name = ""; depends = String_map.empty }

     let to_json dune_project =
       let obj = Js.Dict.empty () in
       Js.Dict.set obj "name" (Js.Json.string dune_project.name);
       let depends =
         String_map.to_list dune_project.depends
         |> List.map (fun (key, (value : string option)) ->
                ( key,
                  if Option.is_some value then Js.Json.string (Option.get value)
                  else Js.Json.null ))
         |> Js.Dict.fromList |> Js.Json.object_
       in
       Js.Dict.set obj "depends" depends;
       Js.Json.object_ obj
     ;;
   end)

   module Extension = struct
     (*
            - A extension can do two things:
               - Register a new template (e.g copy a new template file to the project)
               - Extend an existing template (e.g. add dependencies to package.json)
               - Copy files
        *)
     type action = unit -> (unit, string) result

     module type S = sig
       val name : unit -> string
       val run : unit -> (unit, string) result
     end

     module Config = struct
       module type S = sig
         type t

         val name : string
         val template : (module Template.S) option
         val templates_to_extend : (module Template.S) String_map.t
         val actions : action list
       end
     end
   end

   module Webpack_extension_config = struct
     let name = "webpack"
     let template : (module Template.S) option = None

     let templates_to_extend =
       String_map.empty
       |> String_map.add Package_json.name (module Package_json : Template.S)
     ;;
   end

   module Context = struct
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
