open Package_json
open Context_plugin
module String_map = Map.Make (String)

let dev_dependencies =
  [
    Dependency.make ~kind:`Development ~name:"vite" ~version:"^4.5.0";
    Dependency.make ~kind:`Development ~name:"vite-plugin-melange"
      ~version:"^2.2.0";
  ]
;;

let scripts =
  [
    Script.make ~name:"dev" ~script:"vite";
    Script.make ~name:"serve" ~script:"vite preview";
    Script.make ~name:"bundle" ~script:"vite build";
  ]
;;

module Copy_vite_config_js :
  Process.S with type input = string and type output = unit = struct
  type input = string
  type output = unit

  let name = "copy vite.config.js"

  let vite_config_js_path =
    Node.Path.join
      [|
        Nodejs.Util.__dirname ();
        "..";
        "templates";
        "extensions";
        "vite";
        "vite.config.js";
      |]
  ;;

  let exec (project_dir_name : input) =
    let dest = Node.Path.join [| project_dir_name; "/"; "vite.config.js" |] in
    Fs.copy_file ~dest vite_config_js_path
  ;;
end

module Plugin = struct
  module Extend_package_json = struct
    include Plugin.Make_extension (struct
      include Package_json.Template

      let stage = `Pre_compile

      let extend_template pkg =
        (* Add dependencies to package.json *)
        let pkg =
          dev_dependencies
          |> List.fold_left (Fun.flip Package_json.add_dependency) pkg
        in
        (* Add scripts to package.json *)
        scripts
        |> List.fold_left (Fun.flip Package_json.add_script) pkg
        |> Result.ok |> Js.Promise.resolve
      ;;
    end)
  end

  module Copy_vite_config_js = struct
    include Plugin.Make_process (struct
      include Copy_vite_config_js

      let stage = `Pre_compile
      let input_of_context (ctx : Context.t) = Ok ctx.configuration.name
    end)
  end
end
